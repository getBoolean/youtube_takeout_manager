import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/model_capabilities.dart';
import 'ai_errors.dart';
import 'ai_pacer.dart';
import 'ai_request.dart';

part 'anthropic_repository.g.dart';

@Riverpod(keepAlive: true)
AnthropicRepository anthropicRepository(Ref ref) {
  final repository = AnthropicRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// Asks Anthropic's Claude for an answer shaped by a JSON schema, over the
/// Messages API (Dart has no official SDK). Requests are paced to the
/// limits each reply reports; busy, overloaded or rate-limited, it waits and
/// asks again within [RetryPolicy.claude]'s caps; a rejected key, a model
/// the key can't use, or an account out of credit isn't asked again.
class AnthropicRepository {
  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');
  static final _models = Uri.parse('https://api.anthropic.com/v1/models');
  static const _version = '2023-06-01';

  final http.Client _client;

  /// Whether this runs in a browser, where the API only answers when told
  /// the key is meant to be used there.
  final bool browser;
  final AiPacer _pacer;
  final AiRequester _requester;

  AnthropicRepository({
    http.Client? client,
    bool browser = kIsWeb,
    AiPacer? pacer,
    RetryPolicy policy = RetryPolicy.claude,
    Now? now,
    Sleep? sleep,
    double Function()? jitter,
  }) : this._(
         client ?? http.Client(),
         browser,
         pacer ?? AdaptivePacer(now: now, sleep: sleep),
         policy,
         now,
         sleep,
         jitter,
       );

  AnthropicRepository._(
    this._client,
    this.browser,
    this._pacer,
    RetryPolicy policy,
    Now? now,
    Sleep? sleep,
    double Function()? jitter,
  ) : _requester = AiRequester(
        client: _client,
        policy: policy,
        pacer: _pacer,
        now: now,
        sleep: sleep,
        jitter: jitter,
      );

  /// Asks [model] with [apiKey], under [system], about [user], for JSON
  /// matching [schema], and gives it decoded. What [model] supports decides
  /// the effort asked for and how long the answer may be; a model that
  /// can't answer in shapes isn't asked. Throws an [AiFailure].
  Future<Map<String, Object?>> structured({
    required String apiKey,
    required ModelCapabilities model,
    required String system,
    required String user,
    required Map<String, Object?> schema,
  }) => guardAi(secret: apiKey, () async {
    if (!model.structuredOutputs) {
      throw AiModelUnavailable(
        "${model.id} can't answer in the shape categorizing needs.",
      );
    }
    final body = jsonEncode({
      'model': model.id,
      'max_tokens': model.answerTokens,
      'system': system,
      'messages': [
        {'role': 'user', 'content': user},
      ],
      'output_config': {
        'format': {'type': 'json_schema', 'schema': schema},
        if (model.lowEffort) 'effort': 'low',
      },
    });
    return _requester.send(
      apiKey: apiKey,
      tokens: body.length ~/ 4,
      request: (abort) =>
          http.AbortableRequest('POST', _endpoint, abortTrigger: abort)
            ..headers.addAll({
              ..._headers(apiKey),
              'content-type': 'application/json',
            })
            ..body = body,
      read: (response) => _reply(response, _answer),
    );
  });

  /// What [model] can do, from the Models API, which costs nothing; it also
  /// checks [apiKey] and that the model exists. Not paced, so a pause
  /// doesn't hold it. Throws an [AiFailure].
  Future<ModelCapabilities> capabilities({
    required String apiKey,
    required String model,
  }) => _requester.send(
    apiKey: apiKey,
    paced: false,
    policy: RetryPolicy.keyCheck,
    request: (abort) => http.AbortableRequest(
      'GET',
      _models.replace(pathSegments: [..._models.pathSegments, model]),
      abortTrigger: abort,
    )..headers.addAll(_headers(apiKey)),
    read: (response) => _reply(
      response,
      (body) => switch (_tryDecode(body)) {
        final Map<String, Object?> json => ModelCapabilities.fromModelsApi(
          model,
          json,
        ),
        _ => throw const AiNoAnswer(),
      },
    ),
  );

  /// Holds every request until [until], e.g. restoring a pause Claude asked
  /// for before the app was closed.
  void pauseUntil(DateTime until) => _pacer.pauseUntil(until);

  Map<String, String> _headers(String apiKey) => {
    'x-api-key': apiKey,
    'anthropic-version': _version,
    if (browser) 'anthropic-dangerous-direct-browser-access': 'true',
  };

  /// What Claude's [response] comes to, [answer] reading a 200's body.
  static AiReply<T> _reply<T>(
    http.Response response,
    T Function(String body) answer,
  ) {
    final status = response.statusCode;
    if (status == 200) return AiAnswered(answer(response.body));
    final message = apiErrorMessage(response.body);
    final billing = message == null
        ? const AiBillingProblem()
        : AiBillingProblem(message);
    final spendCap = switch (_tryDecode(response.body)) {
      {'error': {'details': {'error_code': 'enforced_spend_limit_reached'}}} =>
        true,
      _ => false,
    };
    if (status == 429 && spendCap) return AiRefused(billing);
    if (status == 400 &&
        message != null &&
        (message.startsWith('You have reached your specified') ||
            message.toLowerCase().contains('credit'))) {
      return AiRefused(billing);
    }
    return switch (status) {
      400 || 413 || 422 => AiRefused(
        message == null ? const AiBadRequest() : AiBadRequest(message),
      ),
      401 || 403 => const AiRefused(AiKeyRejected()),
      402 => AiRefused(billing),
      404 => AiRefused(
        message == null
            ? const AiModelUnavailable()
            : AiModelUnavailable(message),
      ),
      // Only with a stated wait: without one, it's a limit that won't lift
      // within a few tries.
      429 when requestedWait(response.headers) != null => const AiTryAgain(
        AiRateLimited(),
      ),
      429 => const AiRefused(AiRateLimited()),
      500 || 529 => const AiTryAgain(AiOverloaded()),
      408 || >= 500 => const AiRefused(AiOverloaded()),
      _ => AiRefused(AiBadRequest('Claude answered $status.')),
    };
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

  void close() => _client.close();
}
