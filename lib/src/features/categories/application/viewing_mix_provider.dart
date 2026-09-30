import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/history/application/history_providers.dart';
import '../domain/viewing_mix.dart';
import 'channel_categories.dart';

part 'viewing_mix_provider.g.dart';

/// What was watched by category, of the kinds of videos shown (Shorts and
/// YouTube Music as filtered), whatever else narrows what's shown: every
/// watched channel, and the ones subscribed to but never watched.
@riverpod
List<CategoryShare> viewingMix(Ref ref) {
  final channels = ref.watch(loadedHistoryProvider).watchedChannels;
  final counts = ref.watch(historyChannelWatchCountsProvider);
  final unwatched = ref.watch(
    historySubscriptionMatchProvider.select((m) => m.unwatched),
  );
  final categories = ref.watch(channelCategoriesProvider).value ?? const {};
  return computeViewingMix(
    channels: [
      for (final (i, watched) in channels.indexed)
        (key: watched.channel.key, count: counts[i]),
      for (final channel in unwatched) (key: channel.key, count: 0),
    ],
    categoryOf: (key) => categories[key]?.path,
  );
}
