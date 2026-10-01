import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_pacer.dart';

/// A clock that moves only when something sleeps, recording each sleep.
class _Clock {
  DateTime now = DateTime.utc(2026, 10, 1, 12);
  final sleeps = <Duration>[];

  DateTime call() => now;

  Future<void> sleep(Duration wait) async {
    sleeps.add(wait);
    now = now.add(wait);
  }
}

http.Response _reply(int status, [Map<String, String> headers = const {}]) =>
    http.Response('', status, headers: headers);

/// Whether [future] has finished once pending work has run.
Future<bool> _finished(Future<void> future) async {
  var finished = false;
  unawaited(future.then((_) => finished = true));
  await pumpEventQueue();
  return finished;
}

void main() {
  group('Jev pacing', () {
    test(
      'over the request rate, a turn waits for the bucket to refill',
      () async {
        final clock = _Clock();
        final pacer = BucketPacer(
          concurrency: 10,
          requestsPerSecond: 2,
          now: clock.call,
          sleep: clock.sleep,
        );

        for (var i = 0; i < 2; i++) {
          (await pacer.turn()).done();
        }
        expect(clock.sleeps, isEmpty);

        (await pacer.turn()).done();
        expect(clock.sleeps, const [Duration(milliseconds: 500)]);
      },
    );

    test('a turn wanting more tokens than are left waits for them', () async {
      final clock = _Clock();
      final pacer = BucketPacer(
        tokensPerSecond: 1000,
        now: clock.call,
        sleep: clock.sleep,
      );

      (await pacer.turn(tokens: 1500)).done();

      expect(clock.sleeps, const [Duration(milliseconds: 500)]);
    });

    test('the bucket refills as time passes', () async {
      final clock = _Clock();
      final pacer = BucketPacer(
        concurrency: 10,
        requestsPerSecond: 2,
        now: clock.call,
        sleep: clock.sleep,
      );
      for (var i = 0; i < 2; i++) {
        (await pacer.turn()).done();
      }

      clock.now = clock.now.add(const Duration(seconds: 1));
      (await pacer.turn()).done();

      expect(clock.sleeps, isEmpty);
    });

    test('at most 3 at once: the 4th waits for one to be done', () async {
      final clock = _Clock();
      final pacer = BucketPacer(now: clock.call, sleep: clock.sleep);
      final turns = [for (var i = 0; i < 3; i++) await pacer.turn()];

      final fourth = pacer.turn();
      expect(await _finished(fourth), isFalse);

      turns.first.done();
      expect(await _finished(fourth), isTrue);
    });

    test('a turn done twice frees only one place', () async {
      final clock = _Clock();
      final pacer = BucketPacer(
        concurrency: 2,
        now: clock.call,
        sleep: clock.sleep,
      );
      final first = await pacer.turn();
      await pacer.turn();

      first
        ..done()
        ..done();
      await pacer.turn();

      expect(await _finished(pacer.turn()), isFalse);
    });
  });

  group('a pause', () {
    test('holds every turn until it ends', () async {
      final clock = _Clock();
      final pacer = BucketPacer(now: clock.call, sleep: clock.sleep)
        ..pauseUntil(clock.now.add(const Duration(seconds: 10)));

      (await pacer.turn()).done();
      (await pacer.turn()).done();

      expect(clock.sleeps, const [Duration(seconds: 10)]);
    });

    test('more than a minute away fails a turn at once, saying when', () async {
      final clock = _Clock();
      final until = clock.now.add(const Duration(seconds: 120));
      final pacer = BucketPacer(now: clock.call, sleep: clock.sleep)
        ..pauseUntil(until);

      await expectLater(
        pacer.turn(),
        throwsA(
          isA<AiRateLimited>().having((f) => f.resumeAt, 'resumeAt', until),
        ),
      );
      expect(clock.sleeps, isEmpty);
    });

    test('only ever moves later', () {
      final clock = _Clock();
      final later = clock.now.add(const Duration(seconds: 30));
      final pacer = BucketPacer(now: clock.call, sleep: clock.sleep)
        ..pauseUntil(later)
        ..pauseUntil(clock.now.add(const Duration(seconds: 5)));

      expect(pacer.pausedUntil, later);
    });

    test('that fails a turn leaves the others none the worse', () async {
      final clock = _Clock();
      final pacer = BucketPacer(
        concurrency: 1,
        now: clock.call,
        sleep: clock.sleep,
      );
      final held = await pacer.turn();
      final waiting = pacer.turn();
      pacer.pauseUntil(clock.now.add(const Duration(minutes: 5)));

      held.done();
      await expectLater(waiting, throwsA(isA<AiRateLimited>()));

      clock.now = clock.now.add(const Duration(minutes: 6));
      expect(await _finished(pacer.turn()), isTrue);
    });
  });

  group('Claude pacing', () {
    test('starts one at a time', () async {
      final clock = _Clock();
      final pacer = AdaptivePacer(now: clock.call, sleep: clock.sleep);
      final first = await pacer.turn();

      final second = pacer.turn();
      expect(await _finished(second), isFalse);

      first.done(_reply(200));
      expect(await _finished(second), isTrue);
    });

    test('adds one at a time per 20 answers, up to 3, and drops back to 1 on '
        'a 429', () async {
      final clock = _Clock();
      final pacer = AdaptivePacer(now: clock.call, sleep: clock.sleep);
      Future<void> answer(int times) async {
        for (var i = 0; i < times; i++) {
          (await pacer.turn()).done(_reply(200));
        }
      }

      await answer(19);
      expect(pacer.concurrency, 1);
      await answer(1);
      expect(pacer.concurrency, 2);
      await answer(20);
      expect(pacer.concurrency, 3);
      await answer(40);
      expect(pacer.concurrency, 3);

      (await pacer.turn()).done(_reply(429));
      expect(pacer.concurrency, 1);
    });

    test(
      'with few output tokens left, the next turn waits for the reset',
      () async {
        final clock = _Clock();
        final pacer = AdaptivePacer(now: clock.call, sleep: clock.sleep);
        final reset = clock.now.add(const Duration(seconds: 10));

        (await pacer.turn()).done(
          _reply(200, {
            'anthropic-ratelimit-output-tokens-remaining': '100',
            'anthropic-ratelimit-output-tokens-reset': reset.toIso8601String(),
          }),
        );
        (await pacer.turn()).done(_reply(200));

        expect(clock.sleeps, const [Duration(seconds: 10)]);
      },
    );

    test('with plenty left, the next turn does not wait', () async {
      final clock = _Clock();
      final pacer = AdaptivePacer(now: clock.call, sleep: clock.sleep);
      final reset = clock.now
          .add(const Duration(seconds: 10))
          .toIso8601String();

      (await pacer.turn(tokens: 500)).done(
        _reply(200, {
          'anthropic-ratelimit-requests-remaining': '40',
          'anthropic-ratelimit-requests-reset': reset,
          'anthropic-ratelimit-input-tokens-remaining': '40000',
          'anthropic-ratelimit-input-tokens-reset': reset,
          'anthropic-ratelimit-output-tokens-remaining': '8000',
          'anthropic-ratelimit-output-tokens-reset': reset,
        }),
      );
      (await pacer.turn(tokens: 500)).done(_reply(200));

      expect(clock.sleeps, isEmpty);
    });

    test(
      'a request in flight holds what it needs against what is left',
      () async {
        final clock = _Clock();
        final pacer = AdaptivePacer(now: clock.call, sleep: clock.sleep);
        final reset = clock.now
            .add(const Duration(seconds: 10))
            .toIso8601String();
        (await pacer.turn()).done(
          _reply(200, {
            'anthropic-ratelimit-input-tokens-remaining': '1000',
            'anthropic-ratelimit-input-tokens-reset': reset,
          }),
        );
        // Two at a time, so a second turn can be had while one is held.
        for (var i = 0; i < 20; i++) {
          (await pacer.turn()).done(_reply(200));
        }

        await pacer.turn(tokens: 800);
        await pacer.turn(tokens: 800);

        expect(clock.sleeps, const [Duration(seconds: 10)]);
      },
    );

    test(
      'a reset more than a minute away fails the turn, saying when',
      () async {
        final clock = _Clock();
        final pacer = AdaptivePacer(now: clock.call, sleep: clock.sleep);
        final reset = clock.now.add(const Duration(seconds: 90));

        (await pacer.turn()).done(
          _reply(429, {
            'anthropic-ratelimit-requests-remaining': '0',
            'anthropic-ratelimit-requests-reset': reset.toIso8601String(),
          }),
        );

        await expectLater(
          pacer.turn(),
          throwsA(
            isA<AiRateLimited>().having((f) => f.resumeAt, 'resumeAt', reset),
          ),
        );
        expect(clock.sleeps, isEmpty);
      },
    );

    test('headers that cannot be read are ignored', () async {
      final clock = _Clock();
      final pacer = AdaptivePacer(now: clock.call, sleep: clock.sleep);

      (await pacer.turn()).done(
        _reply(200, {
          'anthropic-ratelimit-requests-remaining': 'none',
          'anthropic-ratelimit-requests-reset': 'soon',
          'anthropic-ratelimit-output-tokens-remaining': '0',
          'anthropic-ratelimit-output-tokens-reset': 'tomorrow',
        }),
      );
      (await pacer.turn()).done(_reply(200));

      expect(clock.sleeps, isEmpty);
    });
  });
}
