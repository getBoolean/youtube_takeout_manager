import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ai_errors.dart';

part 'anthropic_repository.g.dart';

@Riverpod(keepAlive: true)
AnthropicRepository anthropicRepository(Ref ref) {
  final repository = AnthropicRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// Asks Anthropic's Claude for an answer shaped by a JSON schema, over the
/// Messages API (Dart has no official SDK). Busy, overloaded or
/// rate-limited, it waits and asks again; a rejected key, a model the key
/// can't use, or an account out of credit isn't asked again.
class AnthropicRepository {
  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');
  static const _version = '2023-06-01';
  static const _timeout = Duration(seconds: 60);

  final http.Client _client;

  /// Whether this runs in a browser, where the API only answers when told
  /// the key is meant to be used there.
  final bool browser;
  final Future<void> Function(Duration) _sleep;
  final int maxAttempts;
  final _random = Random();

  AnthropicRepository({
    http.Client? client,
    this.browser = kIsWeb,
    Future<void> Function(Duration)? sleep,
    this.maxAttempts = 4,
  }) : _client = client ?? http.Client(),
       _sleep = sleep ?? Future<void>.delayed;

  /// Asks [model] with [apiKey], under [system], about [user], for JSON
  /// matching [schema], and gives it decoded. Throws an [AiFailure].
  Future<Map<String, Object?>> structured({
    required String apiKey,
    required String model,
    required String system,
    required String user,
    required Map<String, Object?> schema,
  }) async {
    // Haiku takes neither thinking nor effort; larger models think by
    // default, so they're asked to think little, with room to.
    final haiku = model.contains('haiku');
    final body = jsonEncode({
      'model': model,
      'max_tokens': haiku ? 1024 : 4096,
      'system': system,
      'messages': [
        {'role': 'user', 'content': user},
      ],
      'output_config': {
        'format': {'type': 'json_schema', 'schema': schema},
        if (!haiku) 'effort': 'low',
      },
    });
    for (var attempt = 1; ; attempt++) {
      final http.Response response;
      try {
        response = await _client
            .post(
              _endpoint,
              headers: {
                'x-api-key': apiKey,
                'anthropic-version': _version,
                'content-type': 'application/json',
                if (browser)
                  'anthropic-dangerous-direct-browser-access': 'true',
              },
              body: body,
            )
            .timeout(_timeout);
      } on Object catch (e) {
        if (e is! http.ClientException && e is! TimeoutException) rethrow;
        if (attempt >= maxAttempts) throw const AiUnreachable();
        await _sleep(_backoff(attempt, null));
        continue;
      }
      switch (response.statusCode) {
        case 200:
          return _answer(response.body);
        case 401 || 403:
          throw const AiKeyRejected();
        case 404:
          throw const AiModelUnavailable();
        case 400 || 402 || 413 || 422:
          throw _refusedRequest(response.body);
        case final status when status == 429 || status >= 500:
          if (attempt >= maxAttempts) {
            throw status == 429 ? const AiRateLimited() : const AiOverloaded();
          }
          await _sleep(_backoff(attempt, response.headers['retry-after']));
        default:
          throw AiBadRequest('Claude answered ${response.statusCode}.');
      }
    }
  }

  /// A request refused as it was: for want of credit, or unreadable.
  static AiFailure _refusedRequest(String body) {
    final message = switch (_tryDecode(body)) {
      {'error': {'message': final String message}} => message,
      _ => '',
    };
    return message.toLowerCase().contains('credit')
        ? const AiBillingProblem()
        : const AiBadRequest();
  }

  static Object? _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on Object {
      return null;
    }
  }

  /// The JSON Claude answered with, only once it finished: a refusal, or an
  /// answer cut off, is no answer.
  static Map<String, Object?> _answer(String body) {
    final json = _tryDecode(body);
    if (json case {
      'stop_reason': 'end_turn',
      'content': final List<dynamic> content,
    }) {
      for (final block in content) {
        if (block case {'type': 'text', 'text': final String text}) {
          if (_tryDecode(text) case final Map<String, Object?> answer) {
            return answer;
          }
        }
      }
    }
    throw const AiNoAnswer();
  }

  /// How long to wait before try [attempt] + 1: what the API said, else a
  /// second, doubling each time, with some jitter.
  Duration _backoff(int attempt, String? retryAfter) {
    if (int.tryParse(retryAfter ?? '') case final seconds? when seconds >= 0) {
      return Duration(seconds: seconds);
    }
    final base = 1000 * pow(2, attempt - 1);
    return Duration(milliseconds: base.toInt() + _random.nextInt(250));
  }

  void close() => _client.close();
}
