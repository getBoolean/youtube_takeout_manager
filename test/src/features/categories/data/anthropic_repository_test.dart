import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';

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

Future<Map<String, Object?>> _ask(
  http.Client client, {
  String model = 'claude-haiku-4-5',
  bool browser = false,
  Future<void> Function(Duration)? sleep,
  int maxAttempts = 4,
}) =>
    AnthropicRepository(
      client: client,
      browser: browser,
      sleep: sleep ?? (_) async {},
      maxAttempts: maxAttempts,
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
    // Haiku takes neither.
    expect(body.containsKey('thinking'), isFalse);
    expect(
      (body['output_config'] as Map<String, dynamic>).containsKey('effort'),
      isFalse,
    );
  });

  test('a larger model is asked to think little, with room to', () async {
    late Map<String, dynamic> body;
    await _ask(
      MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json(_message({'parent': 'Gaming'}));
      }),
      model: 'claude-sonnet-5',
    );

    expect((body['output_config'] as Map<String, dynamic>)['effort'], 'low');
    expect(body['max_tokens'], greaterThan(1024));
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
      sleep: (wait) async => waits.add(wait),
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
        maxAttempts: 2,
      ),
      throwsA(isA<AiRateLimited>()),
    );
  });
}
