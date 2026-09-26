import 'sign_in_profile.dart';

/// How a sign-in went.
sealed class SignInOutcome {
  const SignInOutcome();
}

/// Signed in with the viewed channel.
class SignedIn extends SignInOutcome {
  final SignInProfile profile;

  const SignedIn(this.profile);
}

/// Signed in with a different channel than the viewed one. The sign-in is
/// saved for its own channel; the viewed channel stays signed out.
class SignedInOtherChannel extends SignInOutcome {
  final SignInProfile profile;
  final String viewedChannelId;

  const SignedInOtherChannel(this.profile, {required this.viewedChannelId});
}

/// The chosen Google account has no YouTube channel. Nothing was saved.
class SignInNoChannel extends SignInOutcome {
  const SignInNoChannel();
}

/// The user cancelled, or a newer sign-in replaced this one.
class SignInCancelled extends SignInOutcome {
  const SignInCancelled();
}
