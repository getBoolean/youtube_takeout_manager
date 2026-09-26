import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'saved_sign_ins.dart';

part 'signed_in_channels.g.dart';

/// Titles of the channels with a saved sign-in, by channel ID, from the
/// YouTube API at sign-in. Names takeout channels their saved data gives no
/// title, e.g. data saved before channel lists were kept.
@Riverpod(keepAlive: true)
Map<String, String> signedInChannelTitles(Ref ref) => {
  for (final profile
      in (ref.watch(savedSignInsProvider).value ?? const {}).values)
    profile.channelId: ?profile.channelTitle,
};

/// Pictures of the channels with a saved sign-in, by channel ID, from the
/// YouTube API at sign-in.
@Riverpod(keepAlive: true)
Map<String, String> signedInChannelThumbnails(Ref ref) => {
  for (final profile
      in (ref.watch(savedSignInsProvider).value ?? const {}).values)
    profile.channelId: ?profile.channelThumbnailUrl,
};
