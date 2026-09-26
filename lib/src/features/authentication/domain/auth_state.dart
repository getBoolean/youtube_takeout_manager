import 'package:dart_mappable/dart_mappable.dart';

import 'sign_in_profile.dart';

part 'auth_state.mapper.dart';

/// The viewed channel's sign-in: which channel it's for, and the Google
/// account it belongs to.
@MappableClass()
class AuthState with AuthStateMappable {
  final String channelId;
  final String? channelTitle;
  final String? channelThumbnailUrl;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const AuthState({
    required this.channelId,
    this.channelTitle,
    this.channelThumbnailUrl,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  factory AuthState.fromProfile(SignInProfile profile) => AuthState(
    channelId: profile.channelId,
    channelTitle: profile.channelTitle,
    channelThumbnailUrl: profile.channelThumbnailUrl,
    displayName: profile.displayName,
    email: profile.email,
    photoUrl: profile.photoUrl,
  );
}
