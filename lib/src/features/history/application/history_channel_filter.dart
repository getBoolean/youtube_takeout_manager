import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/watched_channels.dart';

part 'history_channel_filter.g.dart';

/// The channel the history screen's watches are narrowed to, or null for
/// every channel.
@riverpod
class HistoryChannelFilter extends _$HistoryChannelFilter {
  @override
  HistoryChannel? build() => null;

  void show(HistoryChannel channel) => state = channel;

  void clear() => state = null;
}
