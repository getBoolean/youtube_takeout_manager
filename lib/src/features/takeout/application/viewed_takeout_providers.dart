import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';

import '../domain/takeout_channel.dart';
import '../domain/takeout_data.dart';
import 'takeout_notifier.dart';
import 'takeout_selection_notifier.dart';

part 'viewed_takeout_providers.g.dart';

/// The selected takeout's channels, main first. Empty until it has loaded.
@Riverpod(keepAlive: true)
List<TakeoutChannel> takeoutChannels(Ref ref) {
  final loaded = ref.watch(takeoutProvider).value;
  final takeoutId = ref.watch(
    takeoutSelectionProvider.select((s) => s.value?.takeoutId),
  );
  if (loaded == null || loaded.id != takeoutId) return const [];
  return withThumbnails(
    withTitles(
      takeoutChannelsOf(loaded.data, takeoutId: loaded.id),
      ref.watch(signedInChannelTitlesProvider),
    ),
    ref.watch(ownChannelThumbnailsProvider),
  );
}

/// Pictures for takeout channels: from saved sign-ins, else channel pictures
/// already loaded, by channel ID.
@Riverpod(keepAlive: true)
Map<String, String> ownChannelThumbnails(Ref ref) => {
  ...ref.watch(channelThumbnailsProvider),
  ...ref.watch(signedInChannelThumbnailsProvider),
};

/// The channel being viewed: the one last chosen in the selected takeout
/// while it's still there, otherwise the takeout's main channel.
@Riverpod(keepAlive: true)
TakeoutChannel? viewedChannel(Ref ref) {
  final channels = ref.watch(takeoutChannelsProvider);
  final id = resolveViewedChannelId(
    channels,
    remembered: ref.watch(
      takeoutSelectionProvider.select((s) => s.value?.channelId),
    ),
  );
  return channels.where((c) => c.channelId == id).firstOrNull;
}

@Riverpod(keepAlive: true)
String? viewedChannelId(Ref ref) => ref.watch(viewedChannelProvider)?.channelId;

/// The viewed channel's comments and live chats from the selected takeout.
///
/// Plainly loading, without the previous takeout's data, while another
/// takeout loads, so the old one never shows as the new one. (Async
/// providers keep their previous value while they reload.)
@Riverpod(keepAlive: true)
AsyncValue<TakeoutData?> viewedTakeout(Ref ref) {
  final takeout = ref.watch(takeoutProvider);
  final selection = ref.watch(takeoutSelectionProvider);
  if (takeout.isLoading || selection.isLoading) return const AsyncLoading();
  // The selection's first: the takeout fails with it too, wrapped.
  if (selection.error case final error?) {
    return AsyncError(error, selection.stackTrace ?? StackTrace.empty);
  }
  if (takeout.error case final error?) {
    return AsyncError(error, takeout.stackTrace ?? StackTrace.empty);
  }

  final loaded = takeout.value;
  if (loaded == null) return const AsyncData(null);
  if (loaded.id != selection.value?.takeoutId) return const AsyncLoading();

  final channel = ref.watch(viewedChannelProvider);
  final main = ref.watch(
    takeoutChannelsProvider.select((cs) => cs.firstOrNull?.channelId),
  );
  if (channel == null || main == null) return AsyncData(loaded.data);
  return AsyncData(
    onlyChannel(loaded.data, channel.channelId, mainChannelId: main),
  );
}
