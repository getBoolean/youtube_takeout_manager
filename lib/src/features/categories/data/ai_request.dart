import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:youtube_takeout_manager/src/config/ai_config.dart';

import 'ai_errors.dart';
import 'ai_pacer.dart';

typedef Now = DateTime Function();
typedef Sleep = Future<void> Function(Duration wait);

/// How a service is asked again: how many tries in all, how long to wait
/// between them, and how long each may take.
class RetryPolicy {
  /// Tries in all, the first included.
  final int attempts;
  final Duration firstBackoff;
  final Duration maxBackoff;

  /// How long one try may take before it's aborted.
  final Duration timeout;

  /// How many tries that took too long are tried again, when capped: a
  /// request that took too long may still have been billed.
  final int? timeoutRetries;

  /// The longest stated wait waited out; a longer one fails at once,
  /// saying when to resume.
  final Duration longestWait;

  const RetryPolicy({
    required this.attempts,
    required this.firstBackoff,
    required this.maxBackoff,
    required this.timeout,
    this.timeoutRetries,
    this.longestWait = const Duration(seconds: 60),
  });

  /// TypeSafe's SDK policy for Jev.
  static const jev = RetryPolicy(
    attempts: 3,
    firstBackoff: Duration(milliseconds: 500),
    maxBackoff: Duration(seconds: 5),
    timeout: Duration(seconds: 30),
  );

  /// Anthropic's SDK policy for Claude.
  static const claude = RetryPolicy(
    attempts: 3,
    firstBackoff: Duration(seconds: 1),
    maxBackoff: Duration(seconds: 8),
    timeout: Duration(seconds: 60),
    timeoutRetries: 1,
  );

  /// Checking a key, while someone waits for the answer.
  static const keyCheck = RetryPolicy(
    attempts: 2,
    firstBackoff: Duration(milliseconds: 500),
    maxBackoff: Duration(seconds: 1),
    timeout: Duration(seconds: 15),
  );

  /// The wait after try [attempt]: [firstBackoff], doubling each time, at
  /// most [maxBackoff], shortened by up to a quarter by [jitter] in [0, 1).
  Duration backoff(int attempt, double jitter) {
    final doubled = firstBackoff * pow(2, attempt - 1).toDouble();
    final capped = doubled < maxBackoff ? doubled : maxBackoff;
    return capped * (1 - 0.25 * jitter.clamp(0, 1));
  }
}

/// What a service's reply comes to.
sealed class AiReply<T> {
  const AiReply();
}

/// An answer.
final class AiAnswered<T> extends AiReply<T> {
  final T value;

  const AiAnswered(this.value);
}

/// No answer this time, for [failure]; asking again may get one.
final class AiTryAgain<T> extends AiReply<T> {
  final AiFailure failure;

  const AiTryAgain(this.failure);
}

/// No answer, for [failure]; asking again would get none either.
final class AiRefused<T> extends AiReply<T> {
  final AiFailure failure;

  const AiRefused(this.failure);
}

/// How long [headers] ask to wait before asking again: `retry-after-ms`,
/// else `retry-after` in whole seconds. Null when they don't say, or say it
/// in a way that can't be read, such as a date.
Duration? requestedWait(Map<String, String> headers) {
  if (double.tryParse(headers['retry-after-ms'] ?? '') case final ms?
      when ms >= 0 && ms.isFinite) {
    return Duration(microseconds: (ms * 1000).round());
  }
  if (int.tryParse(headers['retry-after']?.trim() ?? '') case final seconds?
      when seconds >= 0) {
    return Duration(seconds: seconds);
  }
  return null;
}

/// Runs [body], turning anything it throws into an [AiFailure] that never
/// quotes [secret].
Future<T> guardAi<T>(
  Future<T> Function() body, {
  required String secret,
}) async {
  try {
    return await body();
  } on Object catch (e) {
    throw aiFailureOf(e, secret: secret);
  }
}

/// Sends requests to an AI service: each try paced, under a timeout,
/// aborted when it takes too long, tried again within the policy's caps,
/// waiting what the service asks or backing off. Every outcome is an answer
/// or an [AiFailure].
class AiRequester {
  final http.Client _client;
  final RetryPolicy _policy;
  final AiPacer? _pacer;
  final Now _now;
  final Sleep _sleep;
  final double Function() _jitter;

  AiRequester({
    required http.Client client,
    required RetryPolicy policy,
    AiPacer? pacer,
    Now? now,
    Sleep? sleep,
    double Function()? jitter,
  }) : _client = client,
       _policy = policy,
       _pacer = pacer,
       _now = now ?? DateTime.now,
       _sleep = sleep ?? Future<void>.delayed,
       _jitter = jitter ?? Random().nextDouble;

  /// Sends what [request] builds, with [apiKey] in it, until [read] makes an
  /// answer of a reply, and gives it. [request] is given the future that
  /// aborts it. Each try takes a turn from the pacer for about [tokens],
  /// unless not [paced]. Throws an [AiFailure] that never quotes [apiKey].
  Future<T> send<T>({
    required String apiKey,
    required http.BaseRequest Function(Future<void> abort) request,
    required AiReply<T> Function(http.Response response) read,
    int tokens = 0,
    bool paced = true,
    RetryPolicy? policy,
  }) => guardAi(secret: apiKey, () async {
    if (!isHeaderSafeKey(apiKey)) {
      throw const AiKeyRejected(
        "The key has characters a request can't carry, such as a space or "
        'a line break.',
      );
    }
    final rules = policy ?? _policy;
    final pacer = paced ? _pacer : null;
    var timeouts = 0;
    for (var attempt = 1; ; attempt++) {
      final last = attempt >= rules.attempts;
      final turn = await pacer?.turn(tokens: tokens);
      final abort = Completer<void>();
      http.Response? response;
      (Object, StackTrace)? error;
      try {
        response = await () async {
          final streamed = await _client.send(request(abort.future));
          return http.Response.fromStream(streamed);
        }().timeout(rules.timeout);
      } on Object catch (e, stack) {
        error = (e, stack);
      } finally {
        // Given back before any wait, so others needn't wait on this one.
        turn?.done(response);
      }
      if (error case (final e, final stack)) {
        final timedOut = e is TimeoutException || abort.isCompleted;
        if (!timedOut && e is! http.ClientException) {
          Error.throwWithStackTrace(e, stack);
        }
        if (timedOut) {
          if (!abort.isCompleted) abort.complete();
          timeouts++;
          if (last || timeouts > (rules.timeoutRetries ?? timeouts)) {
            throw const AiOverloaded("The service didn't answer in time.");
          }
        } else if (last) {
          throw const AiUnreachable();
        }
        await _sleep(rules.backoff(attempt, _jitter()));
        continue;
      }
      final answered = response!;
      switch (read(answered)) {
        case AiAnswered(:final value):
          return value;
        case AiRefused(:final failure):
          throw failure;
        case AiTryAgain(:final failure):
          final wait = requestedWait(answered.headers);
          final resumeAt = wait == null ? null : _now().add(wait);
          // A 429's wait holds the whole service: the requests about to be
          // sent would run into the same limit.
          final holdsAll = answered.statusCode == 429;
          if (resumeAt != null && (holdsAll || wait! > rules.longestWait)) {
            pacer?.pauseUntil(resumeAt);
          }
          if (wait != null && wait > rules.longestWait) {
            throw _resumingAt(failure, resumeAt!);
          }
          if (last) {
            throw resumeAt == null ? failure : _resumingAt(failure, resumeAt);
          }
          if (wait == null || !holdsAll || pacer == null) {
            await _sleep(wait ?? rules.backoff(attempt, _jitter()));
          }
      }
    }
  });

  /// [failure], saying the service can be asked again at [resumeAt].
  static AiFailure _resumingAt(AiFailure failure, DateTime resumeAt) =>
      switch (failure) {
        AiRateLimited(:final message) => AiRateLimited(message, resumeAt),
        AiOverloaded(:final message) => AiOverloaded(message, resumeAt),
        _ => failure,
      };
}
