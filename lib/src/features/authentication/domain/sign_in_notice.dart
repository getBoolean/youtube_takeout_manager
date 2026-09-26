import 'sign_in_profile.dart';

/// Why a channel didn't end up signed in, to show on its row.
sealed class SignInNotice {
  const SignInNotice();
}

/// Another channel was chosen when signing in. Its sign-in is saved for
/// [chosen]; the channel signed in for stays signed out.
class OtherChannelChosen extends SignInNotice {
  final SignInProfile chosen;

  const OtherChannelChosen(this.chosen);
}

/// The Google account chosen has no YouTube channel. Nothing was saved.
class NoYouTubeChannel extends SignInNotice {
  const NoYouTubeChannel();
}

/// Signing in failed, e.g. offline.
class SignInFailed extends SignInNotice {
  final String message;

  const SignInFailed(this.message);
}

/// The channel's saved sign-in stopped working and was removed.
class SignInStoppedWorking extends SignInNotice {
  const SignInStoppedWorking();
}
