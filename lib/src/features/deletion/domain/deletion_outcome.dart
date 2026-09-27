/// How deleting one item from YouTube went.
sealed class DeletionOutcome {
  const DeletionOutcome();
}

final class Deleted extends DeletionOutcome {
  const Deleted();
}

/// The daily API quota ran out.
final class QuotaExceeded extends DeletionOutcome {
  final String message;

  const QuotaExceeded(this.message);
}

/// The sign-in stopped working (access revoked, account deleted) before
/// YouTube could answer. Not the item's fault.
final class SignInFailed extends DeletionOutcome {
  const SignInFailed();
}

final class Failed extends DeletionOutcome {
  final String message;

  const Failed(this.message);
}
