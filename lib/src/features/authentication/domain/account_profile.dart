import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'sign_in_profile.dart';

/// The saved sign-in that names a takeout's Google account: its main
/// channel's, else any of its channels', in [channels]' order (main first).
/// Null when none of them has signed in.
SignInProfile? accountProfileFor(
  List<TakeoutChannel> channels,
  Map<String, SignInProfile> profiles,
) {
  for (final channel in channels) {
    if (profiles[channel.channelId] case final profile?) return profile;
  }
  return null;
}
