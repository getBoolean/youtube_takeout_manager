import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/watch_filters.dart';

part 'watch_filter_providers.g.dart';

/// Whether the history screen's watched videos are narrowed to channels
/// subscribed to, or to the others.
@riverpod
class HistorySubscriptionFilter extends _$HistorySubscriptionFilter {
  @override
  SubscriptionFilter build() => SubscriptionFilter.all;

  void set(SubscriptionFilter filter) => state = filter;
}

/// Whether the history screen's Shorts are shown, alone, or hidden.
@riverpod
class HistoryShortsFilter extends _$HistoryShortsFilter {
  @override
  ShowFilter build() => ShowFilter.all;

  void set(ShowFilter filter) => state = filter;
}

/// Whether the history screen's videos watched on YouTube Music are shown,
/// alone, or hidden.
@riverpod
class HistoryMusicFilter extends _$HistoryMusicFilter {
  @override
  ShowFilter build() => ShowFilter.all;

  void set(ShowFilter filter) => state = filter;
}
