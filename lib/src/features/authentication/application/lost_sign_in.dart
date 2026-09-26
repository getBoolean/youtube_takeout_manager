import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/sign_in_profile.dart';

part 'lost_sign_in.g.dart';

/// A sign-in that stopped working and was removed. Compared by identity, so
/// each loss is reported even if the same channel's is lost twice.
class LostSignIn {
  final SignInProfile profile;

  LostSignIn(this.profile);
}

/// The last sign-in that stopped working, for the UI to report.
@Riverpod(keepAlive: true)
class LostSignInNotifier extends _$LostSignInNotifier {
  @override
  LostSignIn? build() => null;

  void report(SignInProfile profile) => state = LostSignIn(profile);

  void dismiss() => state = null;
}
