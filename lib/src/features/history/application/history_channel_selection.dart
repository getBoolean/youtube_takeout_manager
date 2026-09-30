import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/watch_filters.dart';
import '../domain/watched_channels.dart';

part 'history_channel_selection.g.dart';

/// The channels the history screen's watched videos are narrowed to; none
/// for every channel.
@riverpod
class HistoryChannelSelection extends _$HistoryChannelSelection {
  @override
  ChannelSelection build() => const ChannelSelection();

  /// Narrows the watched videos to [channel]'s alone.
  void showOnly(HistoryChannel channel) =>
      state = ChannelSelection(channels: {channel.key: channel});

  void set(ChannelSelection selection) => state = selection;

  void removeChannel(String key) =>
      state = ChannelSelection(channels: {...state.channels}..remove(key));

  void clear() => state = const ChannelSelection();
}
