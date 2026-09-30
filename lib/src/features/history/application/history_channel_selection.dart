import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import '../domain/watch_filters.dart';
import '../domain/watched_channels.dart';

part 'history_channel_selection.g.dart';

/// The channels the history screen's watched videos are narrowed to, and
/// the categories whose channels are; none for every channel.
@riverpod
class HistoryChannelSelection extends _$HistoryChannelSelection {
  @override
  ChannelSelection build() => const ChannelSelection();

  /// Narrows the watched videos to [channel]'s alone.
  void showOnly(HistoryChannel channel) =>
      state = ChannelSelection(channels: {channel.key: channel});

  void set(ChannelSelection selection) => state = selection;

  void removeChannel(String key) => state = ChannelSelection(
    channels: {...state.channels}..remove(key),
    categories: state.categories,
  );

  void removeCategory(CategoryPick pick) => state = ChannelSelection(
    channels: state.channels,
    categories: {...state.categories}..remove(pick),
  );

  void clear() => state = const ChannelSelection();
}
