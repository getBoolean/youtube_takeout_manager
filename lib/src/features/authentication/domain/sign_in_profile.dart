import 'package:dart_mappable/dart_mappable.dart';

part 'sign_in_profile.mapper.dart';

/// Who a saved sign-in is: the YouTube channel chosen when signing in, and
/// the Google account it belongs to.
@MappableClass()
class SignInProfile with SignInProfileMappable {
  final String channelId;
  final String? channelTitle;

  /// The channel's @handle, from the YouTube API.
  final String? channelHandle;
  final String? channelThumbnailUrl;

  /// The Google account's name, email and photo.
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const SignInProfile({
    required this.channelId,
    this.channelTitle,
    this.channelHandle,
    this.channelThumbnailUrl,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}
