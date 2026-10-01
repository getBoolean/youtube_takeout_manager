import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'ai_errors.dart';
import 'ai_request.dart';

/// Leave to send one request; [done] gives it back, with the reply when
/// there is one. Giving it back twice counts once.
abstract interface class AiTurn {
  void done([http.BaseResponse? response]);
}

/// Keeps an AI service's requests within its limits: how many run at once,
/// whatever else the service limits, and a pause the service asked for,
/// which holds every request.
abstract class AiPacer {
  final Now _now;
  final Sleep _sleep;

  /// The longest wait a turn waits out; a longer one fails it at once.
  final Duration longestWait;

  AiPacer({
    Now? now,
    Sleep? sleep,
    this.longestWait = const Duration(seconds: 60),
  }) : _now = now ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed;

  DateTime? _pausedUntil;
  int _running = 0;
  final _waiting = Queue<Completer<void>>();

  /// How many requests may run at once.
  int get concurrency;

  /// When the service said it can be asked again, if it said so.
  DateTime? get pausedUntil => _pausedUntil;

  /// Holds every request until [until]; only ever moves the pause later.
  void pauseUntil(DateTime until) {
    if (_pausedUntil case final paused? when !until.isAfter(paused)) return;
    _pausedUntil = until;
  }

  /// Waits for a turn to send a request of about [tokens]. Throws
  /// [AiRateLimited], with when to resume, when that's further off than
  /// [longestWait].
  Future<AiTurn> turn({int tokens = 0}) async {
    await _place();
    try {
      await _waitOutPause();
      await _budget(tokens);
    } on Object {
      _free();
      rethrow;
    }
    return _Turn(this, tokens);
  }

  /// Waits for one of the [concurrency] places.
  Future<void> _place() {
    if (_waiting.isEmpty && _running < concurrency) {
      _running++;
      return Future.value();
    }
    final place = Completer<void>();
    _waiting.add(place);
    return place.future;
  }

  void _free() {
    _running--;
    _letIn();
  }

  /// Gives free places to those waiting, first come first served.
  void _letIn() {
    while (_waiting.isNotEmpty && _running < concurrency) {
      _running++;
      _waiting.removeFirst().complete();
    }
  }

  /// Waits for a pause to end: one sleep, then another only if the pause
  /// moved later meanwhile. Never polls the clock.
  Future<void> _waitOutPause() async {
    for (;;) {
      final until = _pausedUntil;
      if (until == null) return;
      final wait = until.difference(_now());
      if (wait <= Duration.zero) return;
      if (wait > longestWait) throw AiRateLimited(_tooMany, until);
      await _sleep(wait);
      if (_pausedUntil == until) return;
    }
  }

  /// Waits until the service's other limits leave room for a request of
  /// [tokens], and holds that room until the turn is done.
  Future<void> _budget(int tokens);

  /// Settles the turn for [tokens] given back with [response].
  void _settle(int tokens, http.BaseResponse? response) {}

  static const _tooMany = 'Too many requests for now.';
}

class _Turn implements AiTurn {
  final AiPacer _pacer;
  final int _tokens;
  bool _done = false;

  _Turn(this._pacer, this._tokens);

  @override
  void done([http.BaseResponse? response]) {
    if (_done) return;
    _done = true;
    _pacer._settle(_tokens, response);
    _pacer._free();
  }
}

/// Jev's documented limits: requests and tokens per second, each a bucket
/// that refills steadily, and a few requests at once. A request takes what
/// it costs at once, into debt if need be, and waits once for the debt to
/// refill.
class BucketPacer extends AiPacer {
  @override
  final int concurrency;
  final _Bucket _requests;
  final _Bucket _tokens;

  BucketPacer({
    this.concurrency = 3,
    double requestsPerSecond = 40,
    double tokensPerSecond = 100000,
    super.now,
    super.sleep,
    super.longestWait,
  }) : _requests = _Bucket(requestsPerSecond),
       _tokens = _Bucket(tokensPerSecond);

  @override
  Future<void> _budget(int tokens) async {
    final now = _now();
    final wait = [
      _requests.take(1, now),
      _tokens.take(tokens, now),
    ].reduce((a, b) => a > b ? a : b);
    if (wait > Duration.zero) await _sleep(wait);
  }
}

/// Holds up to a second's worth at [perSecond], refilling steadily.
class _Bucket {
  final double perSecond;
  late double _level = perSecond;
  DateTime? _filledAt;

  _Bucket(this.perSecond);

  /// Takes [cost] at [now], into debt if need be, and gives how long until
  /// the debt is paid off.
  Duration take(num cost, DateTime now) {
    if (_filledAt case final filledAt?) {
      final seconds = now.difference(filledAt).inMicroseconds / 1e6;
      if (seconds > 0) _level = min(perSecond, _level + seconds * perSecond);
    }
    _filledAt = now;
    _level -= cost;
    if (_level >= 0) return Duration.zero;
    return Duration(microseconds: (-_level / perSecond * 1e6).ceil());
  }
}

/// Claude's limits, which depend on the account's tier, so they're learned
/// from each reply's `anthropic-ratelimit-*` headers. It starts one at a
/// time and adds one per [rampEvery] answers up to [maxConcurrency], as
/// Anthropic asks; a 429 drops it back to one.
class AdaptivePacer extends AiPacer {
  final int maxConcurrency;
  final int rampEvery;

  /// The output tokens a request may use, held against what's left.
  final int outputTokens;

  int _concurrency = 1;
  int _answered = 0;
  final _requests = _Limit('requests');
  final _input = _Limit('input-tokens');
  final _output = _Limit('output-tokens');

  AdaptivePacer({
    this.maxConcurrency = 3,
    this.rampEvery = 20,
    this.outputTokens = 1024,
    super.now,
    super.sleep,
    super.longestWait,
  });

  @override
  int get concurrency => _concurrency;

  List<(_Limit, int)> _needs(int tokens) => [
    (_requests, 1),
    (_input, tokens),
    (_output, outputTokens),
  ];

  @override
  Future<void> _budget(int tokens) async {
    final needs = _needs(tokens);
    final now = _now();
    DateTime? until;
    for (final (limit, need) in needs) {
      if (limit.covers(need)) continue;
      final reset = limit.reset;
      if (reset == null || !reset.isAfter(now)) {
        // Reset already: what was left is no longer known to be short.
        limit.remaining = null;
      } else if (until == null || reset.isAfter(until)) {
        until = reset;
      }
    }
    if (until != null) {
      final wait = until.difference(now);
      if (wait > longestWait) throw AiRateLimited(AiPacer._tooMany, until);
      await _sleep(wait);
      for (final (limit, need) in needs) {
        if (!limit.covers(need)) limit.remaining = null;
      }
    }
    for (final (limit, need) in needs) {
      limit.held += need;
    }
  }

  @override
  void _settle(int tokens, http.BaseResponse? response) {
    for (final (limit, need) in _needs(tokens)) {
      limit.held -= need;
    }
    if (response == null) return;
    for (final limit in [_requests, _input, _output]) {
      limit.read(response.headers);
    }
    final status = response.statusCode;
    if (status == 429) {
      _concurrency = 1;
      _answered = 0;
    } else if (status >= 200 && status < 300 && ++_answered >= rampEvery) {
      _answered = 0;
      if (_concurrency < maxConcurrency) {
        _concurrency++;
        _letIn();
      }
    }
  }
}

/// One of Claude's limits: what's left, when it's full again, and what the
/// requests in flight hold of it.
class _Limit {
  final String _name;
  int? remaining;
  DateTime? reset;
  int held = 0;

  _Limit(this._name);

  /// Whether what's left, less what's held, covers [need]; unknown covers
  /// anything.
  bool covers(int need) => switch (remaining) {
    null => true,
    final left => left - held >= need,
  };

  /// Takes what [headers] say is left and when it resets, ignoring what
  /// can't be read.
  void read(Map<String, String> headers) {
    final left = int.tryParse(
      headers['anthropic-ratelimit-$_name-remaining'] ?? '',
    );
    final resets = DateTime.tryParse(
      headers['anthropic-ratelimit-$_name-reset'] ?? '',
    );
    if (left == null || resets == null) return;
    remaining = left;
    reset = resets;
  }
}
