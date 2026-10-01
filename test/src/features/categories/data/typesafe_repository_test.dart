import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';

http.Response _json(
  Object body, [
  int status = 200,
  Map<String, String>? headers,
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...?headers},
);

final _answers = {
  'answers': {
    'fits_0': {'type': 'noul', 'noul': 0.93},
    'parent': {
      'type': 'choice',
      'choice': 'gaming',
      'probabilities': {'gaming': 0.8, 'music': 0.2},
      'confidence': 0.7,
    },
  },
  'usage': {'input_tokens': 312, 'output_tokens': 0},
};

Future<void> _noSleep(Duration _) async {}

const _questions = {
  'fits_0': JevNoul('Does Gaming describe it?'),
  'parent': JevChoice('Which category?', {
    'gaming': 'Video games',
    'music': null,
  }),
};

void main() {
  test('asks Jev with the key, what it knows, and each question', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return _json(_answers);
    });

    await TypeSafeRepository(client: client, sleep: _noSleep).ask(
      apiKey: 'jv_live_1',
      state: {'channel': 'Gamer'},
      questions: _questions,
    );

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://api.typesafe.ai/v1/systemone');
    expect(sent.headers['Authorization'], 'Bearer jv_live_1');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['model'], 'jev-latest');
    expect(body['state'], {'channel': 'Gamer'});
    final questions = body['questions'] as Map<String, dynamic>;
    expect(questions['fits_0']['type'], 'noul');
    expect(questions['parent']['type'], 'choice');
    expect(questions['parent']['criteria'], {
      'gaming': 'Video games',
      'music': null,
    });
  });

  test('reads yes-or-no and choice answers', () async {
    final answers = await TypeSafeRepository(
      client: MockClient((_) async => _json(_answers)),
      sleep: _noSleep,
    ).ask(apiKey: 'k', state: 's', questions: _questions);

    expect((answers['fits_0']! as NoulAnswer).yes, 0.93);
    final choice = answers['parent']! as ChoiceAnswer;
    expect(choice.choice, 'gaming');
    expect(choice.probabilities['music'], 0.2);
    expect(choice.confidence, 0.7);
  });

  test('a key Jev rejects says so, without asking again', () async {
    var requests = 0;
    final repository = TypeSafeRepository(
      client: MockClient((_) async {
        requests++;
        return _json({'error': 'invalid key'}, 401);
      }),
      sleep: _noSleep,
    );

    await expectLater(
      repository.ask(apiKey: 'k', state: 's', questions: _questions),
      throwsA(isA<AiKeyRejected>()),
    );
    expect(requests, 1);
  });

  test('a request Jev cannot read says so', () async {
    await expectLater(
      TypeSafeRepository(
        client: MockClient((_) async => _json({'error': 'bad'}, 422)),
        sleep: _noSleep,
      ).ask(apiKey: 'k', state: 's', questions: _questions),
      throwsA(isA<AiBadRequest>()),
    );
  });

  test('when busy, Jev is asked again, waiting longer each time, as long '
      'as it says to', () async {
    final statuses = [429, 529, 200];
    final waits = <Duration>[];
    var now = DateTime.utc(2026, 10, 1);
    final answers = await TypeSafeRepository(
      client: MockClient((_) async {
        final status = statuses.removeAt(0);
        return status == 200
            ? _json(_answers)
            : _json(
                {'error': 'busy'},
                status,
                status == 429 ? {'retry-after': '7'} : null,
              );
      }),
      now: () => now,
      sleep: (wait) async {
        waits.add(wait);
        now = now.add(wait);
      },
    ).ask(apiKey: 'k', state: 's', questions: _questions);

    expect(answers, isNotEmpty);
    expect(waits.first, const Duration(seconds: 7));
    expect(waits, hasLength(2));
  });

  test('still busy after every try, it gives up saying so', () async {
    final waits = <Duration>[];
    await expectLater(
      TypeSafeRepository(
        client: MockClient((_) async => _json({'error': 'busy'}, 529)),
        sleep: (wait) async => waits.add(wait),
      ).ask(apiKey: 'k', state: 's', questions: _questions),
      throwsA(isA<AiOverloaded>()),
    );
    expect(waits, hasLength(2));
    expect(waits.last, greaterThan(waits.first));
  });

  test("when Jev can't be reached, it says so", () async {
    await expectLater(
      TypeSafeRepository(
        client: MockClient((_) async => throw http.ClientException('offline')),
        sleep: _noSleep,
      ).ask(apiKey: 'k', state: 's', questions: _questions),
      throwsA(isA<AiUnreachable>()),
    );
  });

  test('a choice has at most 255 options', () {
    expect(
      () => JevChoice('Which?', {
        for (var i = 0; i < 256; i++) 'o$i': null,
      }).toJson(),
      throwsArgumentError,
    );
  });

  test('a request that timed out at the server is tried again', () async {
    final statuses = [408, 200];
    final answers = await TypeSafeRepository(
      client: MockClient((_) async {
        final status = statuses.removeAt(0);
        return status == 200 ? _json(_answers) : _json({'error': 'slow'}, 408);
      }),
      sleep: _noSleep,
    ).ask(apiKey: 'k', state: 's', questions: _questions);

    expect(answers, isNotEmpty);
    expect(statuses, isEmpty);
  });

  for (final status in [400, 422]) {
    test('a $status says what Jev said was wrong', () async {
      await expectLater(
        TypeSafeRepository(
          client: MockClient(
            (_) async => _json({
              'error': {'message': 'questions.parent has no options'},
            }, status),
          ),
          sleep: _noSleep,
        ).ask(apiKey: 'k', state: 's', questions: _questions),
        throwsA(
          isA<AiBadRequest>().having(
            (f) => f.message,
            'message',
            contains('questions.parent has no options'),
          ),
        ),
      );
    });
  }

  test('a question with more than 255 options fails without asking', () async {
    var requests = 0;
    await expectLater(
      TypeSafeRepository(
        client: MockClient((_) async {
          requests++;
          return _json(_answers);
        }),
        sleep: _noSleep,
      ).ask(
        apiKey: 'k',
        state: 's',
        questions: {
          'parent': JevChoice('Which?', {
            for (var i = 0; i < 256; i++) 'o$i': null,
          }),
        },
      ),
      throwsA(isA<AiFailure>()),
    );
    expect(requests, 0);
  });

  test('state that cannot be put in JSON fails as unexpected', () async {
    await expectLater(
      TypeSafeRepository(
        client: MockClient((_) async => _json(_answers)),
        sleep: _noSleep,
      ).ask(apiKey: 'k', state: Object(), questions: _questions),
      throwsA(isA<AiUnexpected>()),
    );
  });

  test('at most 3 are asked at once', () async {
    var running = 0;
    var most = 0;
    final release = Completer<void>();
    final repository = TypeSafeRepository(
      client: MockClient((_) async {
        most = max(most, ++running);
        await release.future;
        running--;
        return _json(_answers);
      }),
      sleep: _noSleep,
    );

    final asked = [
      for (var i = 0; i < 5; i++)
        repository.ask(apiKey: 'k', state: 's', questions: _questions),
    ];
    await pumpEventQueue();
    expect(running, 3);
    release.complete();
    await Future.wait(asked);

    expect(most, 3);
  });

  test('a pause further off than a minute fails asking at once, saying '
      'when to resume', () async {
    var requests = 0;
    final resumeAt = DateTime.now().add(const Duration(minutes: 5));
    final repository = TypeSafeRepository(
      client: MockClient((_) async {
        requests++;
        return _json(_answers);
      }),
      sleep: _noSleep,
    )..pauseUntil(resumeAt);

    await expectLater(
      repository.ask(apiKey: 'k', state: 's', questions: _questions),
      throwsA(
        isA<AiRateLimited>().having((f) => f.resumeAt, 'resumeAt', resumeAt),
      ),
    );
    expect(requests, 0);
  });

  group('checking a key', () {
    test("lists Jev's models with the key", () async {
      late http.Request sent;
      await TypeSafeRepository(
        client: MockClient((request) async {
          sent = request;
          return _json({'data': <Object>[]});
        }),
        sleep: _noSleep,
      ).checkKey('jv_live_1');

      expect(sent.method, 'GET');
      expect(sent.url.toString(), 'https://api.typesafe.ai/v1/models');
      expect(sent.headers['Authorization'], 'Bearer jv_live_1');
    });

    test('a rejected key says so', () async {
      await expectLater(
        TypeSafeRepository(
          client: MockClient((_) async => _json({'error': 'no'}, 401)),
          sleep: _noSleep,
        ).checkKey('jv_live_1'),
        throwsA(isA<AiKeyRejected>()),
      );
    });

    test("when Jev can't be reached, it says so", () async {
      await expectLater(
        TypeSafeRepository(
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
          sleep: _noSleep,
        ).checkKey('jv_live_1'),
        throwsA(isA<AiUnreachable>()),
      );
    });

    test('is not held by a pause', () async {
      final repository = TypeSafeRepository(
        client: MockClient((_) async => _json({'data': <Object>[]})),
        sleep: _noSleep,
      )..pauseUntil(DateTime.now().add(const Duration(minutes: 5)));

      await repository.checkKey('jv_live_1');
    });
  });
}
