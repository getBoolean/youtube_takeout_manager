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

/// Asked too often, even after waiting.
class AiRateLimited extends AiFailure {
  const AiRateLimited([super.message = 'Too many requests for now.']);
}

/// The service is too busy, even after waiting.
class AiOverloaded extends AiFailure {
  const AiOverloaded([super.message = 'The service is busy.']);
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
