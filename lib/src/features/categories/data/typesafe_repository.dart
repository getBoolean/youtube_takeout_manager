import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ai_errors.dart';
import 'ai_pacer.dart';
import 'ai_request.dart';

part 'typesafe_repository.g.dart';

@Riverpod(keepAlive: true)
TypeSafeRepository typeSafeRepository(Ref ref) {
  final repository = TypeSafeRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// A question for Jev.
sealed class JevQuestion {
  final String instructions;

  const JevQuestion(this.instructions);

  Map<String, Object?> toJson();
}

/// A yes-or-no question; [whenTrue] and [whenFalse] say what each means.
class JevNoul extends JevQuestion {
  final String? whenTrue;
  final String? whenFalse;

  const JevNoul(super.instructions, {this.whenTrue, this.whenFalse});

  @override
  Map<String, Object?> toJson() => {
    'type': 'noul',
    'instructions': instructions,
    if (whenTrue != null || whenFalse != null)
      'criteria': {'true': ?whenTrue, 'false': ?whenFalse},
  };
}

/// A question picking one of [options], each key with what it means (null
/// for nothing more than its key). At most [maxOptions].
class JevChoice extends JevQuestion {
  final Map<String, String?> options;

  const JevChoice(super.instructions, this.options);

  static const maxOptions = 255;

  @override
  Map<String, Object?> toJson() {
    if (options.length > maxOptions) {
      throw ArgumentError.value(
        options.length,
        'options',
        'Jev takes at most $maxOptions',
      );
    }
    return {
      'type': 'choice',
      'instructions': instructions,
      'criteria': options,
    };
  }
}

/// Jev's answer to a question.
sealed class JevAnswer {
  const JevAnswer();
}

/// How likely the answer to a yes-or-no question is yes.
class NoulAnswer extends JevAnswer {
  final double yes;

  const NoulAnswer(this.yes);
}

/// The option picked, how likely each was, and how sure Jev is.
class ChoiceAnswer extends JevAnswer {
  final String choice;
  final Map<String, double> probabilities;
  final double confidence;

  const ChoiceAnswer({
    required this.choice,
    required this.probabilities,
    required this.confidence,
  });
}

/// Asks TypeSafe's Jev, a classifier that picks from options it's given
/// for a fraction of a cent, questions about some state, all in one
/// request. Requests are paced to Jev's documented limits; busy or
/// rate-limited, it waits and asks again within [RetryPolicy.jev]'s caps; a
/// rejected key, or a request it can't read, isn't asked again.
class TypeSafeRepository {
  static final _endpoint = Uri.parse('https://api.typesafe.ai/v1/systemone');
  static final _models = Uri.parse('https://api.typesafe.ai/v1/models');
  static const _model = 'jev-latest';

  final http.Client _client;
  final AiPacer _pacer;
  final AiRequester _requester;

  TypeSafeRepository({
    http.Client? client,
    AiPacer? pacer,
    RetryPolicy policy = RetryPolicy.jev,
    Now? now,
    Sleep? sleep,
    double Function()? jitter,
  }) : this._(
         client ?? http.Client(),
         pacer ?? BucketPacer(now: now, sleep: sleep),
         policy,
         now,
         sleep,
         jitter,
       );

  TypeSafeRepository._(
    this._client,
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

  /// Asks [questions] about [state], a string or JSON, with [apiKey], and
  /// gives each answer by its question's key. Throws an [AiFailure].
  Future<Map<String, JevAnswer>> ask({
    required String apiKey,
    required Object state,
    required Map<String, JevQuestion> questions,
  }) => guardAi(secret: apiKey, () async {
    if (questions.values.any(
      (question) =>
          question is JevChoice &&
          question.options.length > JevChoice.maxOptions,
    )) {
      throw const AiUnexpected(
        'A question offered Jev more than ${JevChoice.maxOptions} options.',
      );
    }
    final body = jsonEncode({
      'model': _model,
      'state': state,
      'questions': {
        for (final MapEntry(:key, :value) in questions.entries)
          key: value.toJson(),
      },
    });
    return _requester.send(
      apiKey: apiKey,
      tokens: body.length ~/ 4,
      request: (abort) =>
          http.AbortableRequest('POST', _endpoint, abortTrigger: abort)
            ..headers.addAll({
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            })
            ..body = body,
      read: (response) => _reply(response, _answers),
    );
  });

  /// Checks [apiKey] by listing Jev's models, which costs nothing. Not
  /// paced, so a pause doesn't hold it. Throws an [AiFailure] when the key
  /// can't be used, or Jev couldn't say.
  Future<void> checkKey(String apiKey) => _requester.send(
    apiKey: apiKey,
    paced: false,
    policy: RetryPolicy.keyCheck,
    request: (abort) =>
        http.AbortableRequest('GET', _models, abortTrigger: abort)
          ..headers['Authorization'] = 'Bearer $apiKey',
    read: (response) => _reply<void>(response, (_) {}),
  );

  /// Holds every question until [until], e.g. restoring a pause Jev asked
  /// for before the app was closed.
  void pauseUntil(DateTime until) => _pacer.pauseUntil(until);

  /// Ends a pause now, e.g. for a new key.
  void resume() => _pacer.resume();

  /// What Jev's [response] comes to, [answer] reading a 200's body.
  static AiReply<T> _reply<T>(
    http.Response response,
    T Function(String body) answer,
  ) => switch (response.statusCode) {
    200 => AiAnswered(answer(response.body)),
    401 || 403 => const AiRefused(AiKeyRejected()),
    402 => AiRefused(switch (apiErrorMessage(response.body)) {
      final message? => AiBillingProblem(message),
      null => const AiBillingProblem(),
    }),
    404 => const AiRefused(AiModelUnavailable()),
    400 || 422 => AiRefused(switch (apiErrorMessage(response.body)) {
      final message? => AiBadRequest(message),
      null => const AiBadRequest(),
    }),
    408 => const AiTryAgain(AiOverloaded("Jev didn't answer in time.")),
    429 => const AiTryAgain(AiRateLimited()),
    >= 500 => const AiTryAgain(AiOverloaded()),
    final status => AiRefused(AiBadRequest('Jev answered $status.')),
  };

  static Map<String, JevAnswer> _answers(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final answers = json['answers'] as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in answers.entries)
          key: _answer(value as Map<String, dynamic>),
      };
    } on AiFailure {
      rethrow;
    } on Object {
      throw const AiNoAnswer();
    }
  }

  static JevAnswer _answer(Map<String, dynamic> json) => switch (json['type']) {
    'noul' => NoulAnswer((json['noul'] as num).toDouble()),
    'choice' => ChoiceAnswer(
      choice: json['choice'] as String,
      probabilities: {
        for (final MapEntry(:key, :value)
            in (json['probabilities'] as Map<String, dynamic>).entries)
          key: (value as num).toDouble(),
      },
      confidence: (json['confidence'] as num).toDouble(),
    ),
    _ => throw const AiNoAnswer(),
  };

  void close() => _client.close();
}
