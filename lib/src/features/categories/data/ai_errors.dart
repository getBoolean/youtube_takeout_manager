import 'dart:convert';

import 'package:http/http.dart' as http;

/// Why an AI service couldn't answer, whichever it was.
sealed class AiFailure implements Exception {
  final String message;

  const AiFailure(this.message);

  @override
  String toString() => message;
}

/// The API key is wrong or was revoked.
class AiKeyRejected extends AiFailure {
  const AiKeyRejected([super.message = 'The API key was rejected.']);
}

/// The account behind the key can't pay for more.
class AiBillingProblem extends AiFailure {
  const AiBillingProblem([super.message = 'The account needs credit.']);
}

/// Asked too often, even after waiting; [resumeAt] is when the service
/// said it can be asked again, if it did.
class AiRateLimited extends AiFailure {
  final DateTime? resumeAt;

  const AiRateLimited([
    super.message = 'Too many requests for now.',
    this.resumeAt,
  ]);
}

/// The service is too busy, even after waiting; [resumeAt] is when the
/// service said it can be asked again, if it did.
class AiOverloaded extends AiFailure {
  final DateTime? resumeAt;

  const AiOverloaded([super.message = 'The service is busy.', this.resumeAt]);
}

/// The service couldn't be reached, e.g. offline, or refused by the browser.
class AiUnreachable extends AiFailure {
  const AiUnreachable([super.message = "The service couldn't be reached."]);
}

/// The service couldn't read the request.
class AiBadRequest extends AiFailure {
  const AiBadRequest([
    super.message = "The service couldn't read the request.",
  ]);
}

/// The model asked for doesn't exist, or the key can't use it.
class AiModelUnavailable extends AiFailure {
  const AiModelUnavailable([super.message = "The model isn't available."]);
}

/// It answered, but not with a usable answer.
class AiNoAnswer extends AiFailure {
  const AiNoAnswer([super.message = 'No usable answer came back.']);
}

/// Something went wrong that no AI service's answer explains, e.g. a bug.
class AiUnexpected extends AiFailure {
  const AiUnexpected(super.message);
}

/// [error] as an [AiFailure], never quoting [secret], raw, JSON-escaped or
/// URL-encoded. An [AiFailure] stays itself unless its message quotes it.
AiFailure aiFailureOf(Object error, {String secret = ''}) {
  final text = switch (error) {
    AiFailure(:final message) => message,
    // Never its source, or toString(), which quotes it: dart:io puts a
    // header's value, the key, there.
    FormatException(:final message) => message,
    _ => '$error',
  };
  final redacted = _redact(text, secret);
  return switch (error) {
    AiFailure() when redacted == error.message => error,
    AiFailure() => _withMessage(error, redacted),
    http.ClientException() => const AiUnreachable(),
    _ => AiUnexpected(_cut(redacted)),
  };
}

/// [text] without [secret] in any of the forms it's written in.
String _redact(String text, String secret) {
  if (secret.isEmpty) return text;
  final json = jsonEncode(secret);
  final forms =
      {
          secret,
          json.substring(1, json.length - 1),
          Uri.encodeComponent(secret),
          Uri.encodeQueryComponent(secret),
        }.where((form) => form.isNotEmpty).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
  for (final form in forms) {
    text = text.replaceAll(form, '[key]');
  }
  return text;
}

/// [text], cut to a length a notice can show.
String _cut(String text) =>
    text.length <= 200 ? text : '${text.substring(0, 199)}…';

AiFailure _withMessage(AiFailure failure, String message) => switch (failure) {
  AiKeyRejected() => AiKeyRejected(message),
  AiBillingProblem() => AiBillingProblem(message),
  AiRateLimited(:final resumeAt) => AiRateLimited(message, resumeAt),
  AiOverloaded(:final resumeAt) => AiOverloaded(message, resumeAt),
  AiUnreachable() => AiUnreachable(message),
  AiBadRequest() => AiBadRequest(message),
  AiModelUnavailable() => AiModelUnavailable(message),
  AiNoAnswer() => AiNoAnswer(message),
  AiUnexpected() => AiUnexpected(message),
};
