import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';

http.Response _json(
  Object body, [
  int status = 200,
  Map<String, String>? headers,
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...?headers},
);

Map<String, Object> _message(Object answer, {String stop = 'end_turn'}) => {
  'id': 'msg_1',
  'type': 'message',
  'role': 'assistant',
  'model': 'claude-haiku-4-5',
  'stop_reason': stop,
  'content': [
    {'type': 'text', 'text': jsonEncode(answer)},
  ],
  'usage': {'input_tokens': 900, 'output_tokens': 40},
};

const _schema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['parent'],
  'properties': {
    'parent': {'type': 'string'},
  },
};

/// A model that answers in shapes, with no effort setting.
const _haiku = ModelCapabilities(
  id: 'claude-haiku-4-5',
  structuredOutputs: true,
  lowEffort: false,
  maxTokens: 64000,
);

Future<Map<String, Object?>> _ask(
  http.Client client, {
  ModelCapabilities model = _haiku,
  bool browser = false,
  DateTime Function()? now,
  Future<void> Function(Duration)? sleep,
}) =>
    AnthropicRepository(
      client: client,
      browser: browser,
      now: now,
      sleep: sleep ?? (_) async {},
    ).structured(
      apiKey: 'sk-ant-1',
      model: model,
      system: 'Categorize the channel.',
      user: '{"channel":"Gamer"}',
      schema: _schema,
    );

void main() {
  test('asks Claude with the key for an answer shaped by the schema', () async {
    late http.Request sent;
    final answer = await _ask(
      MockClient((request) async {
        sent = request;
        return _json(_message({'parent': 'Gaming'}));
      }),
    );

    expect(answer, {'parent': 'Gaming'});
    expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(sent.headers['x-api-key'], 'sk-ant-1');
    expect(sent.headers['anthropic-version'], '2023-06-01');
    expect(
      sent.headers.containsKey('anthropic-dangerous-direct-browser-access'),
      isFalse,
    );
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['model'], 'claude-haiku-4-5');
    expect(body['system'], 'Categorize the channel.');
    expect(body['messages'], [
      {'role': 'user', 'content': '{"channel":"Gamer"}'},
    ]);
    expect(body['output_config'], {
      'format': {'type': 'json_schema', 'schema': _schema},
    });
    // This model takes no effort setting.
    expect(body.containsKey('thinking'), isFalse);
    expect(
      (body['output_config'] as Map<String, dynamic>).containsKey('effort'),
      isFalse,
    );
  });

  group('what the model supports decides the request', () {
    Future<Map<String, dynamic>> sentFor(ModelCapabilities model) async {
      late Map<String, dynamic> body;
      await _ask(
        MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(_message({'parent': 'Gaming'}));
        }),
        model: model,
      );
      return body;
    }

    test('low effort is asked for only when the model supports it, whatever '
        'its name', () async {
      final supported = await sentFor(
        const ModelCapabilities(
          id: 'claude-haiku-4-5',
          structuredOutputs: true,
          lowEffort: true,
        ),
      );
      final unsupported = await sentFor(
        const ModelCapabilities(
          id: 'claude-sonnet-5',
          structuredOutputs: true,
          lowEffort: false,
        ),
      );

      expect(
        (supported['output_config'] as Map<String, dynamic>)['effort'],
        'low',
      );
      expect(
        (unsupported['output_config'] as Map<String, dynamic>).containsKey(
          'effort',
        ),
        isFalse,
      );
    });

    test('an answer may be 1024 tokens long', () async {
      expect((await sentFor(_haiku))['max_tokens'], 1024);
    });

    test("an answer may be only as long as the model's maximum", () async {
      final body = await sentFor(
        const ModelCapabilities(
          id: 'claude-tiny',
          structuredOutputs: true,
          lowEffort: false,
          maxTokens: 300,
        ),
      );

      expect(body['max_tokens'], 300);
    });

    test(
      "a model that can't answer in shapes is refused without asking",
      () async {
        var requests = 0;
        await expectLater(
          _ask(
            MockClient((_) async {
              requests++;
              return _json(_message({'parent': 'Gaming'}));
            }),
            model: const ModelCapabilities(
              id: 'claude-old',
              structuredOutputs: false,
              lowEffort: false,
            ),
          ),
          throwsA(isA<AiModelUnavailable>()),
        );
        expect(requests, 0);
      },
    );
  });

  group("a model's capabilities", () {
    test('are read from the Models API with the key', () async {
      late http.Request sent;
      final model = await AnthropicRepository(
        client: MockClient((request) async {
          sent = request;
          return _json({
            'id': 'claude-sonnet-5-20260801',
            'type': 'model',
            'max_tokens': 64000,
            'capabilities': {
              'structured_outputs': {'supported': true},
              'effort': {
                'low': {'supported': true},
              },
            },
          });
        }),
        browser: false,
        sleep: (_) async {},
      ).capabilities(apiKey: 'sk-ant-1', model: 'claude-sonnet-5');

      expect(sent.method, 'GET');
      expect(
        sent.url.toString(),
        'https://api.anthropic.com/v1/models/claude-sonnet-5',
      );
      expect(sent.headers['x-api-key'], 'sk-ant-1');
      expect(sent.headers['anthropic-version'], '2023-06-01');
      expect(model.id, 'claude-sonnet-5');
      expect(model.structuredOutputs, isTrue);
      expect(model.lowEffort, isTrue);
      expect(model.maxTokens, 64000);
    });

    test("of a model that doesn't exist say it isn't available", () async {
      await expectLater(
        AnthropicRepository(
          client: MockClient(
            (_) async => _json({
              'type': 'error',
              'error': {'type': 'not_found_error', 'message': 'model: nope'},
            }, 404),
          ),
          browser: false,
          sleep: (_) async {},
        ).capabilities(apiKey: 'sk-ant-1', model: 'nope'),
        throwsA(isA<AiModelUnavailable>()),
      );
    });

    test('asked for with a rejected key say so', () async {
      await expectLater(
        AnthropicRepository(
          client: MockClient(
            (_) async => _json({
              'type': 'error',
              'error': {'type': 'authentication_error', 'message': 'invalid'},
            }, 401),
          ),
          browser: false,
          sleep: (_) async {},
        ).capabilities(apiKey: 'sk-ant-1', model: 'claude-sonnet-5'),
        throwsA(isA<AiKeyRejected>()),
      );
    });
  });

  test('from the web app, it says the key is meant to be used there', () async {
    late http.Request sent;
    await _ask(
      MockClient((request) async {
        sent = request;
        return _json(_message({'parent': 'Gaming'}));
      }),
      browser: true,
    );

    expect(sent.headers['anthropic-dangerous-direct-browser-access'], 'true');
  });

  for (final (stop, name) in [
    ('refusal', 'a refusal'),
    ('max_tokens', 'a cut-off answer'),
  ]) {
    test('$name gives no answer', () async {
      await expectLater(
        _ask(
          MockClient((_) async => _json(_message({'parent': 'G'}, stop: stop))),
        ),
        throwsA(isA<AiNoAnswer>()),
      );
    });
  }

  test('a rejected key says so', () async {
    await expectLater(
      _ask(
        MockClient(
          (_) async => _json({
            'type': 'error',
            'error': {'type': 'authentication_error', 'message': 'invalid'},
          }, 401),
        ),
      ),
      throwsA(isA<AiKeyRejected>()),
    );
  });

  test('a model the key can’t use says so', () async {
    await expectLater(
      _ask(
        MockClient(
          (_) async => _json({
            'type': 'error',
            'error': {'type': 'not_found_error', 'message': 'model'},
          }, 404),
        ),
      ),
      throwsA(isA<AiModelUnavailable>()),
    );
  });

  test('an account out of credit says so', () async {
    await expectLater(
      _ask(
        MockClient(
          (_) async => _json({
            'type': 'error',
            'error': {
              'type': 'invalid_request_error',
              'message': 'Your credit balance is too low.',
            },
          }, 400),
        ),
      ),
      throwsA(isA<AiBillingProblem>()),
    );
  });

  test('when busy, Claude is asked again after the wait it gives', () async {
    final statuses = [529, 429, 200];
    final waits = <Duration>[];
    var now = DateTime.utc(2026, 10, 1);
    final answer = await _ask(
      MockClient((_) async {
        final status = statuses.removeAt(0);
        return status == 200
            ? _json(_message({'parent': 'Music'}))
            : _json(
                {
                  'type': 'error',
                  'error': {'type': 'overloaded_error'},
                },
                status,
                status == 429 ? {'retry-after': '4'} : null,
              );
      }),
      now: () => now,
      sleep: (wait) async {
        waits.add(wait);
        now = now.add(wait);
      },
    );

    expect(answer, {'parent': 'Music'});
    expect(waits, hasLength(2));
    expect(waits.last, const Duration(seconds: 4));
  });

  test('still limited after every try, it gives up saying so', () async {
    await expectLater(
      _ask(
        MockClient(
          (_) async => _json({
            'type': 'error',
            'error': {'type': 'rate_limit_error'},
          }, 429),
        ),
      ),
      throwsA(isA<AiRateLimited>()),
    );
  });

  group('spend caps', () {
    test(
      "Anthropic's monthly cap is a billing problem, quoting the API",
      () async {
        var requests = 0;
        await expectLater(
          _ask(
            MockClient((_) async {
              requests++;
              return _json({
                'type': 'error',
                'error': {
                  'type': 'rate_limit_error',
                  'message': 'You have reached your monthly spend cap.',
                  'details': {'error_code': 'enforced_spend_limit_reached'},
                },
              }, 429);
            }),
          ),
          throwsA(
            isA<AiBillingProblem>().having(
              (f) => f.message,
              'message',
              contains('monthly spend cap'),
            ),
          ),
        );
        expect(requests, 1);
      },
    );

    test(
      'a spend limit you set is a billing problem, quoting the API',
      () async {
        await expectLater(
          _ask(
            MockClient(
              (_) async => _json({
                'type': 'error',
                'error': {
                  'type': 'invalid_request_error',
                  'message':
                      'You have reached your specified API usage limits. You '
                      'will regain access on 2026-11-01 at 00:00 UTC.',
                },
              }, 400),
            ),
          ),
          throwsA(
            isA<AiBillingProblem>().having(
              (f) => f.message,
              'message',
              contains('2026-11-01'),
            ),
          ),
        );
      },
    );
  });

  test('a request Claude turns down says why', () async {
    await expectLater(
      _ask(
        MockClient(
          (_) async => _json({
            'type': 'error',
            'error': {
              'type': 'invalid_request_error',
              'message': 'output_config.format: schema too deep',
            },
          }, 400),
        ),
      ),
      throwsA(
        isA<AiBadRequest>().having(
          (f) => f.message,
          'message',
          contains('schema too deep'),
        ),
      ),
    );
  });

  test('a 429 without a stated wait is not tried again, and gives no time '
      'to resume', () async {
    var requests = 0;
    await expectLater(
      _ask(
        MockClient((_) async {
          requests++;
          return _json({
            'type': 'error',
            'error': {'type': 'rate_limit_error', 'message': 'slow down'},
          }, 429);
        }),
      ),
      throwsA(
        isA<AiRateLimited>().having((f) => f.resumeAt, 'resumeAt', isNull),
      ),
    );
    expect(requests, 1);
  });

  test(
    'a stated wait over a minute fails at once, saying when to resume',
    () async {
      var requests = 0;
      final now = DateTime.utc(2026, 10, 1, 12);
      await expectLater(
        _ask(
          MockClient((_) async {
            requests++;
            return _json(
              {
                'type': 'error',
                'error': {'type': 'rate_limit_error', 'message': 'slow down'},
              },
              429,
              {'retry-after': '90'},
            );
          }),
          now: () => now,
        ),
        throwsA(
          isA<AiRateLimited>().having(
            (f) => f.resumeAt,
            'resumeAt',
            now.add(const Duration(seconds: 90)),
          ),
        ),
      );
      expect(requests, 1);
    },
  );

  for (final status in [500, 529]) {
    test('a $status is tried again', () async {
      final statuses = [status, 200];
      final answer = await _ask(
        MockClient((_) async {
          final next = statuses.removeAt(0);
          return next == 200
              ? _json(_message({'parent': 'Music'}))
              : _json({
                  'type': 'error',
                  'error': {'type': 'api_error'},
                }, next);
        }),
      );

      expect(answer, {'parent': 'Music'});
    });
  }

  test('a 503 is not tried again, and fails as busy', () async {
    var requests = 0;
    await expectLater(
      _ask(
        MockClient((_) async {
          requests++;
          return _json({
            'type': 'error',
            'error': {'type': 'api_error'},
          }, 503);
        }),
      ),
      throwsA(isA<AiOverloaded>()),
    );
    expect(requests, 1);
  });

  test('a request that takes too long is tried again only once', () {
    fakeAsync((async) {
      var requests = 0;
      Object? outcome;
      _ask(
        MockClient((_) {
          requests++;
          return Completer<http.Response>().future;
        }),
      ).then<void>((_) {}, onError: (Object e) => outcome = e);

      async.elapse(const Duration(minutes: 10));

      expect(outcome, isA<AiOverloaded>());
      expect(requests, 2);
    });
  });

  test(
    'with few output tokens left, the next request waits for the reset',
    () async {
      var now = DateTime.utc(2026, 10, 1, 12);
      final reset = now.add(const Duration(seconds: 20));
      final waits = <Duration>[];
      final repository = AnthropicRepository(
        client: MockClient(
          (_) async => _json(_message({'parent': 'Music'}), 200, {
            'anthropic-ratelimit-output-tokens-remaining': '50',
            'anthropic-ratelimit-output-tokens-reset': reset.toIso8601String(),
          }),
        ),
        browser: false,
        now: () => now,
        sleep: (wait) async {
          waits.add(wait);
          now = now.add(wait);
        },
      );
      Future<void> ask() => repository.structured(
        apiKey: 'sk-ant-1',
        model: _haiku,
        system: 'Categorize the channel.',
        user: '{}',
        schema: _schema,
      );

      await ask();
      expect(waits, isEmpty);
      await ask();

      expect(waits, const [Duration(seconds: 20)]);
    },
  );

  test('an unexpected error never shows the key', () async {
    final failure = await _ask(
      MockClient(
        (request) async =>
            throw StateError('bad header ${request.headers['x-api-key']}'),
      ),
    ).then<Object>((_) => 'no failure', onError: (Object e) => e);

    expect(failure, isA<AiUnexpected>());
    expect('$failure', isNot(contains('sk-ant-1')));
  });
}
