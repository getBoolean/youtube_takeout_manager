/// What checking an AI service's key found.
enum KeyStatus {
  /// The key can be used.
  works,

  /// The service refused the key, or it can't go in a request.
  rejected,

  /// The key is good, but its account needs credit.
  needsCredit,

  /// The key is good, but can't use the model.
  modelUnavailable,

  /// The service couldn't say: the key is checked when next used.
  unchecked,
}

/// What checking a key found, and what the service said about it.
class KeyCheck {
  final KeyStatus status;
  final String? detail;

  const KeyCheck(this.status, [this.detail]);

  /// Whether the key is kept: all but a rejected one are.
  bool get keeps => status != KeyStatus.rejected;
}
