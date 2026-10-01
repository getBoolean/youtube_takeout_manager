import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_pacer.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_request.dart';

final _url = Uri.parse('https://ai.example/v1/ask');
final _now = DateTime.utc(2026, 10, 1, 12);

const _quick = RetryPolicy(
  attempts: 3,
  firstBackoff: Duration(milliseconds: 500),
  maxBackoff: Duration(seconds: 5),
  timeout: Duration(seconds: 30),
);

http.BaseRequest _post(Future<void> abort) =>
    http.AbortableRequest('POST', _url, abortTrigger: abort)..body = '{}';

/// Reads 200 as the body, a 429 or 5xx as worth trying again, and anything
/// else as refused.
AiReply<String> _read(http.Response response) => switch (response.statusCode) {
  200 => AiAnswered(response.body),
  429 => const AiTryAgain(AiRateLimited()),
  >= 500 => AiTryAgain(AiOverloaded('busy ${response.body}')),
  _ => const AiRefused(AiBadRequest('turned down')),
};

/// An [AiRequester] over [client] that records its sleeps instead of
/// sleeping.
({AiRequester requester, List<Duration> sleeps}) _requester(
  http.Client client, {
  RetryPolicy policy = _quick,
  double jitter = 0,
}) {
  final sleeps = <Duration>[];
  final requester = AiRequester(
    client: client,
    policy: policy,
    now: () => _now,
    sleep: (wait) async => sleeps.add(wait),
    jitter: () => jitter,
  );
  return (requester: requester, sleeps: sleeps);
}

/// Sends [request] through [requester] inside [async], letting [elapse]
/// pass, and gives what it came to: the answer or what it threw.
Object? _sendFaked(
  FakeAsync async,
  AiRequester requester, {
  Duration elapse = const Duration(minutes: 10),
}) {
  Object? outcome;
  requester
      .send(apiKey: 'sk-test', request: _post, read: _read)
      .then<void>(
        (value) => outcome = value,
        onError: (Object e) => outcome = e,
      );
  async.elapse(elapse);
  return outcome;
}

void main() {
  group('a key that cannot go in a header', () {
    for (final key in ['sk ant', 'sk\n']) {
      test('is refused before anything is sent: ${jsonEncode(key)}', () async {
        var requests = 0;
        final (:requester, sleeps: _) = _requester(
          MockClient((_) async {
            requests++;
            return http.Response('ok', 200);
          }),
        );

        await expectLater(
          requester.send(apiKey: key, request: _post, read: _read),
          throwsA(isA<AiKeyRejected>()),
        );
        expect(requests, 0);
      });
    }
  });

  test('an answer comes back as read', () async {
    final (:requester, sleeps: _) = _requester(
      MockClient((_) async => http.Response('the answer', 200)),
    );

    expect(
      await requester.send(apiKey: 'sk-test', request: _post, read: _read),
      'the answer',
    );
  });

  test('a reply worth trying again is tried 3 times in all, then fails as '
      'it last did', () async {
    var requests = 0;
    final (:requester, :sleeps) = _requester(
      MockClient((_) async => http.Response('${++requests}', 503)),
    );

    await expectLater(
      requester.send(apiKey: 'sk-test', request: _post, read: _read),
      throwsA(
        isA<AiOverloaded>().having((f) => f.message, 'message', 'busy 3'),
      ),
    );
    expect(requests, 3);
    expect(sleeps, hasLength(2));
  });

  test('a refused reply is not tried again', () async {
    var requests = 0;
    final (:requester, :sleeps) = _requester(
      MockClient((_) async {
        requests++;
        return http.Response('no', 400);
      }),
    );

    await expectLater(
      requester.send(apiKey: 'sk-test', request: _post, read: _read),
      throwsA(isA<AiBadRequest>()),
    );
    expect(requests, 1);
    expect(sleeps, isEmpty);
  });

  group('backoff', () {
    test('doubles from the first wait and is capped', () {
      expect(
        [
          for (var attempt = 1; attempt <= 6; attempt++)
            _quick.backoff(attempt, 0),
        ],
        const [
          Duration(milliseconds: 500),
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 5),
          Duration(seconds: 5),
        ],
      );
    });

    test('jitter shortens it by at most a quarter', () {
      for (final jitter in [0.0, 0.3, 0.999]) {
        final wait = _quick.backoff(2, jitter);
        expect(wait, lessThanOrEqualTo(const Duration(seconds: 1)));
        expect(wait, greaterThanOrEqualTo(const Duration(milliseconds: 750)));
      }
      expect(_quick.backoff(2, 0.5), lessThan(_quick.backoff(2, 0)));
    });

    test('is what a request waits between tries', () async {
      final (:requester, :sleeps) = _requester(
        MockClient((_) async => http.Response('', 503)),
      );

      await expectLater(
        requester.send(apiKey: 'sk-test', request: _post, read: _read),
        throwsA(isA<AiOverloaded>()),
      );
      expect(sleeps, const [Duration(milliseconds: 500), Duration(seconds: 1)]);
    });
  });

  group('a stated wait', () {
    test('in retry-after seconds is waited before trying again', () async {
      var requests = 0;
      final (:requester, :sleeps) = _requester(
        MockClient(
          (_) async => ++requests == 1
              ? http.Response('', 429, headers: {'retry-after': '2'})
              : http.Response('ok', 200),
        ),
      );

      expect(
        await requester.send(apiKey: 'sk-test', request: _post, read: _read),
        'ok',
      );
      expect(sleeps, const [Duration(seconds: 2)]);
    });

    test('in retry-after-ms is waited before trying again', () async {
      var requests = 0;
      final (:requester, :sleeps) = _requester(
        MockClient(
          (_) async => ++requests == 1
              ? http.Response(
                  '',
                  503,
                  headers: {'retry-after-ms': '1500', 'retry-after': '9'},
                )
              : http.Response('ok', 200),
        ),
      );

      expect(
        await requester.send(apiKey: 'sk-test', request: _post, read: _read),
        'ok',
      );
      expect(sleeps, const [Duration(milliseconds: 1500)]);
    });

    test('over a minute is not waited out, and says when to resume', () async {
      var requests = 0;
      final (:requester, :sleeps) = _requester(
        MockClient((_) async {
          requests++;
          return http.Response('', 429, headers: {'retry-after': '120'});
        }),
      );

      await expectLater(
        requester.send(apiKey: 'sk-test', request: _post, read: _read),
        throwsA(
          isA<AiRateLimited>().having(
            (f) => f.resumeAt,
            'resumeAt',
            _now.add(const Duration(seconds: 120)),
          ),
        ),
      );
      expect(requests, 1);
      expect(sleeps, isEmpty);
    });

    test('that runs out of tries says when to resume', () async {
      final (:requester, sleeps: _) = _requester(
        MockClient(
          (_) async => http.Response('', 503, headers: {'retry-after': '5'}),
        ),
      );

      await expectLater(
        requester.send(apiKey: 'sk-test', request: _post, read: _read),
        throwsA(
          isA<AiOverloaded>().having(
            (f) => f.resumeAt,
            'resumeAt',
            _now.add(const Duration(seconds: 5)),
          ),
        ),
      );
    });

    test('that cannot be read is no stated wait', () {
      expect(
        requestedWait({'retry-after': 'Wed, 21 Oct 2026 07:28:00 GMT'}),
        isNull,
      );
      expect(requestedWait({'retry-after': '-3'}), isNull);
      expect(requestedWait({}), isNull);
    });
  });

  test('connection errors are tried again, then fail as unreachable', () async {
    var requests = 0;
    final (:requester, sleeps: _) = _requester(
      MockClient((_) async {
        requests++;
        throw http.ClientException('offline');
      }),
    );

    await expectLater(
      requester.send(apiKey: 'sk-test', request: _post, read: _read),
      throwsA(isA<AiUnreachable>()),
    );
    expect(requests, 3);
  });

  group('a request that takes too long', () {
    test('is tried again, and its answer used', () {
      fakeAsync((async) {
        var requests = 0;
        final (:requester, sleeps: _) = _requester(
          MockClient(
            (_) => ++requests < 3
                ? Completer<http.Response>().future
                : Future.value(http.Response('late but there', 200)),
          ),
        );

        expect(_sendFaked(async, requester), 'late but there');
        expect(requests, 3);
      });
    });

    test('fails as busy once its tries run out', () {
      fakeAsync((async) {
        var requests = 0;
        final (:requester, sleeps: _) = _requester(
          MockClient((_) {
            requests++;
            return Completer<http.Response>().future;
          }),
        );

        expect(_sendFaked(async, requester), isA<AiOverloaded>());
        expect(requests, 3);
      });
    });

    test('with one timeout retry allowed, fails at the second', () {
      fakeAsync((async) {
        var requests = 0;
        final (:requester, sleeps: _) = _requester(
          MockClient((_) {
            requests++;
            return Completer<http.Response>().future;
          }),
          policy: const RetryPolicy(
            attempts: 3,
            firstBackoff: Duration(seconds: 1),
            maxBackoff: Duration(seconds: 8),
            timeout: Duration(seconds: 60),
            timeoutRetries: 1,
          ),
        );

        expect(_sendFaked(async, requester), isA<AiOverloaded>());
        expect(requests, 2);
      });
    });

    test('is aborted', () {
      fakeAsync((async) {
        final aborted = <bool>[];
        final (:requester, sleeps: _) = _requester(
          _Hanging((request) {
            final trigger = (request as http.Abortable).abortTrigger!;
            aborted.add(false);
            final i = aborted.length - 1;
            unawaited(trigger.then((_) => aborted[i] = true));
          }),
        );

        _sendFaked(async, requester);

        expect(aborted, [true, true, true]);
      });
    });
  });

  group('an unexpected error', () {
    test('becomes a failure that never shows the key', () async {
      const key = 'sk-ant-secret-0123';
      final (:requester, sleeps: _) = _requester(
        MockClient((_) async => http.Response('ok', 200)),
      );

      final failure = await requester
          .send<String>(
            apiKey: key,
            request: _post,
            read: (_) => throw StateError('could not use $key'),
          )
          .then<Object>((_) => 'no failure', onError: (Object e) => e);

      expect(failure, isA<AiUnexpected>());
      expect('$failure', isNot(contains(key)));
      expect((failure as AiFailure).message, isNot(contains(key)));
    });

    test(
      'quoting the key in a header error never shows it, escaped or not',
      () {
        const key = 'sk-ant-se"creté';
        final escaped = jsonEncode(key);
        final failure = aiFailureOf(
          FormatException('Invalid HTTP header field value: $escaped', key, 3),
          secret: key,
        );

        expect(failure, isA<AiUnexpected>());
        expect(failure.message, isNot(contains(key)));
        expect(
          failure.message,
          isNot(contains(escaped.substring(1, escaped.length - 1))),
        );
        expect(failure.message, isNot(contains(Uri.encodeComponent(key))));
      },
    );

    test('that is an AI failure stays the same failure', () {
      const failure = AiBillingProblem('Top up your account.');

      expect(
        identical(aiFailureOf(failure, secret: 'sk-test'), failure),
        isTrue,
      );
    });
  });

  group('with a pacer', () {
    /// A clock that moves only when the pacer sleeps.
    late DateTime now;
    late List<Duration> pacerSleeps;
    late List<Duration> sleeps;

    setUp(() {
      now = _now;
      pacerSleeps = [];
      sleeps = [];
    });

    AiRequester paced(http.Client client, AiPacer pacer) => AiRequester(
      client: client,
      policy: _quick,
      pacer: pacer,
      now: () => now,
      sleep: (wait) async => sleeps.add(wait),
      jitter: () => 0,
    );

    BucketPacer bucket({int concurrency = 3}) => BucketPacer(
      concurrency: concurrency,
      now: () => now,
      sleep: (wait) async {
        pacerSleeps.add(wait);
        now = now.add(wait);
      },
    );

    test("a 429's stated wait pauses the service, and the next try waits "
        'for the pause', () async {
      var requests = 0;
      final pacer = bucket();
      final requester = paced(
        MockClient(
          (_) async => ++requests == 1
              ? http.Response('', 429, headers: {'retry-after': '5'})
              : http.Response('ok', 200),
        ),
        pacer,
      );

      expect(
        await requester.send(apiKey: 'sk-test', request: _post, read: _read),
        'ok',
      );
      expect(pacerSleeps, const [Duration(seconds: 5)]);
      expect(sleeps, isEmpty);
    });

    test('a stated wait over a minute pauses the service until then', () async {
      final pacer = bucket();
      final requester = paced(
        MockClient(
          (_) async => http.Response('', 429, headers: {'retry-after': '120'}),
        ),
        pacer,
      );

      await expectLater(
        requester.send(apiKey: 'sk-test', request: _post, read: _read),
        throwsA(isA<AiRateLimited>()),
      );
      expect(pacer.pausedUntil, _now.add(const Duration(seconds: 120)));
    });

    test('every try gives its turn back with its reply', () async {
      final pacer = AdaptivePacer(
        now: () => now,
        sleep: (wait) async => now = now.add(wait),
      );
      final requester = paced(
        MockClient((_) async => http.Response('ok', 200)),
        pacer,
      );

      for (var i = 0; i < 20; i++) {
        await requester.send(apiKey: 'sk-test', request: _post, read: _read);
      }

      expect(pacer.concurrency, 2);
    });

    test('tries that fail give their turns back', () async {
      var requests = 0;
      final pacer = bucket(concurrency: 1);
      final requester = paced(
        MockClient((_) async {
          if (++requests <= 3) throw http.ClientException('offline');
          return http.Response('ok', 200);
        }),
        pacer,
      );

      await expectLater(
        requester.send(apiKey: 'sk-test', request: _post, read: _read),
        throwsA(isA<AiUnreachable>()),
      );
      expect(
        await requester.send(apiKey: 'sk-test', request: _post, read: _read),
        'ok',
      );
    });

    test('a request sent unpaced is not held by a pause', () async {
      final pacer = bucket()..pauseUntil(_now.add(const Duration(minutes: 5)));
      final requester = paced(
        MockClient((_) async => http.Response('ok', 200)),
        pacer,
      );

      expect(
        await requester.send(
          apiKey: 'sk-test',
          request: _post,
          read: _read,
          paced: false,
        ),
        'ok',
      );
      expect(pacerSleeps, isEmpty);
    });
  });
}

/// A client whose requests never answer, telling [onSend] about each.
class _Hanging extends http.BaseClient {
  final void Function(http.BaseRequest request) onSend;

  _Hanging(this.onSend);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    onSend(request);
    return Completer<http.StreamedResponse>().future;
  }
}
