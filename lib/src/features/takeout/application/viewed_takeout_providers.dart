import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/signed_in_channels.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';

import '../domain/takeout_channel.dart';
import '../domain/takeout_data.dart';
import 'takeout_notifier.dart';
import 'takeout_selection_notifier.dart';

part 'viewed_takeout_providers.g.dart';

/// The selected takeout's channels as the takeout names them, without
/// titles or pictures loaded since. Empty until it has loaded.
@Riverpod(keepAlive: true)
List<TakeoutChannel> _takeoutChannelsAsImported(Ref ref) {
  final loaded = ref.watch(takeoutProvider).value;
  final takeoutId = ref.watch(
    takeoutSelectionProvider.select((s) => s.value?.takeoutId),
  );
  if (loaded == null || loaded.id != takeoutId) return const [];
  return takeoutChannelsOf(loaded.data, takeoutId: loaded.id);
}

/// The selected takeout's channels, main first. Empty until it has loaded.
@Riverpod(keepAlive: true)
List<TakeoutChannel> takeoutChannels(Ref ref) => withThumbnails(
  withTitles(
    ref.watch(_takeoutChannelsAsImportedProvider),
    ref.watch(signedInChannelTitlesProvider),
  ),
  ref.watch(ownChannelThumbnailsProvider),
);

/// Pictures for takeout channels: from saved sign-ins, else channel pictures
/// already loaded, by channel ID.
@Riverpod(keepAlive: true)
Map<String, String> ownChannelThumbnails(Ref ref) => {
  ...?ref.watch(channelThumbnailsProvider).value,
  ...ref.watch(signedInChannelThumbnailsProvider),
};

/// The ID of the channel being viewed: the one last chosen in the selected
/// takeout while it's still there, otherwise the takeout's main channel.
///
/// Worked out without channel titles or pictures, so what depends on it,
/// like the sign-in used to fetch pictures, doesn't depend on those too.
@Riverpod(keepAlive: true)
String? viewedChannelId(Ref ref) => resolveViewedChannelId(
  ref.watch(_takeoutChannelsAsImportedProvider),
  remembered: ref.watch(
    takeoutSelectionProvider.select((s) => s.value?.channelId),
  ),
);

/// The channel being viewed, with its title and picture.
@Riverpod(keepAlive: true)
TakeoutChannel? viewedChannel(Ref ref) {
  final id = ref.watch(viewedChannelIdProvider);
  return ref
      .watch(takeoutChannelsProvider)
      .where((c) => c.channelId == id)
      .firstOrNull;
}

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

  // Channel IDs only, so channel titles and pictures arriving don't reach
  // everything built from this.
  final channelId = ref.watch(viewedChannelIdProvider);
  final main = ref.watch(
    _takeoutChannelsAsImportedProvider.select(
      (cs) => cs.firstOrNull?.channelId,
    ),
  );
  if (channelId == null || main == null) return AsyncData(loaded.data);
  return AsyncData(onlyChannel(loaded.data, channelId, mainChannelId: main));
}
