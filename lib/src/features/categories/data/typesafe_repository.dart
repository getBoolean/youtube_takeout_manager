import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ai_errors.dart';

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
/// request. Busy or rate-limited, it waits and asks again, longer each
/// time; a rejected key, or a request it can't read, isn't asked again.
class TypeSafeRepository {
  static final _endpoint = Uri.parse('https://api.typesafe.ai/v1/systemone');
  static const _model = 'jev-latest';
  static const _timeout = Duration(seconds: 30);

  final http.Client _client;
  final Future<void> Function(Duration) _sleep;
  final int maxAttempts;
  final _random = Random();

  TypeSafeRepository({
    http.Client? client,
    Future<void> Function(Duration)? sleep,
    this.maxAttempts = 5,
  }) : _client = client ?? http.Client(),
       _sleep = sleep ?? Future<void>.delayed;

  /// Asks [questions] about [state], a string or JSON, with [apiKey], and
  /// gives each answer by its question's key. Throws an [AiFailure].
  Future<Map<String, JevAnswer>> ask({
    required String apiKey,
    required Object state,
    required Map<String, JevQuestion> questions,
  }) async {
    final body = jsonEncode({
      'model': _model,
      'state': state,
      'questions': {
        for (final MapEntry(:key, :value) in questions.entries)
          key: value.toJson(),
      },
    });
    for (var attempt = 1; ; attempt++) {
      final http.Response response;
      try {
        response = await _client
            .post(
              _endpoint,
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
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
          return _answers(response.body);
        case 401 || 403:
          throw const AiKeyRejected();
        case 402:
          throw const AiBillingProblem();
        case 404:
          throw const AiModelUnavailable();
        case 400 || 422:
          throw const AiBadRequest();
        case final status when status == 429 || status >= 500:
          if (attempt >= maxAttempts) {
            throw status == 429 ? const AiRateLimited() : const AiOverloaded();
          }
          await _sleep(_backoff(attempt, response.headers['retry-after']));
        default:
          throw AiBadRequest('Jev answered ${response.statusCode}.');
      }
    }
  }

  /// How long to wait before try [attempt] + 1: what the service said, else
  /// a second, doubling each time, with some jitter.
  Duration _backoff(int attempt, String? retryAfter) {
    if (int.tryParse(retryAfter ?? '') case final seconds? when seconds >= 0) {
      return Duration(seconds: seconds);
    }
    final base = 1000 * pow(2, attempt - 1);
    return Duration(milliseconds: base.toInt() + _random.nextInt(250));
  }

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
