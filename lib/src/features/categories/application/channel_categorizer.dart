import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel_details.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../domain/categorization_plan.dart';
import '../domain/channel_category.dart';
import '../domain/channel_evidence.dart';
import '../domain/youtube_topics.dart';
import 'categorization_inputs.dart';
import 'categorization_progress.dart';
import 'category_pipeline.dart';
import 'channel_categories.dart';

part 'channel_categorizer.g.dart';

/// Saved every so many channels, so a long run's categories survive it
/// being cut short.
const _saveEvery = 10;

/// Categorizes the channels watched and subscribed to, the most watched
/// first, once the history screen has been opened. Signed in, it first asks
/// YouTube for the topics of channels it doesn't know them for. A category
/// the user accepted or denied is never replaced. Starts over when the
/// history, subscriptions or sign-in change, dropping the run under way.
///
/// A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class ChannelCategorizer extends _$ChannelCategorizer {
  var _generation = 0;
  Future<void>? _running;
  var _again = false;

  @override
  void build() {
    ref.listen(categorizationInputsProvider, (_, inputs) {
      if (inputs != null) _requestRun();
    }, fireImmediately: true);
    ref.listen(readSessionChannelIdProvider, (previous, next) {
      if (previous == null && next != null) _requestRun();
    });
  }

  /// Runs now, or again once the run under way ends.
  void _requestRun() {
    if (_running != null) {
      _again = true;
      _generation++;
      return;
    }
    _running = _run().whenComplete(() {
      _running = null;
      if (_again && ref.mounted) {
        _again = false;
        _requestRun();
      }
    });
  }

  Future<void> _run() async {
    final generation = ++_generation;
    bool dropped() => generation != _generation || !ref.mounted;

    final inputs = ref.read(categorizationInputsProvider);
    if (inputs == null) return;
    final categories = ref.read(channelCategoriesProvider.notifier);
    final existing = await ref.read(channelCategoriesProvider.future);
    var details = await ref
        .read(channelDetailsProvider.future)
        .catchError((Object _) => const <String, ChannelDetails>{});
    if (dropped()) return;

    final (:loaded, :subscriptions) = inputs;
    final channels = <HistoryChannel>[
      for (final watched in loaded.watchedChannels) watched.channel,
      ...subscriptions.unwatched,
    ];

    // Signed in, the topics of channels that may need them are asked for
    // first, the most watched first.
    if (ref.read(readSessionChannelIdProvider) != null) {
      final lacking = [
        for (final channel in channels)
          if (channel.channelId case final id?)
            if (!details.containsKey(id) &&
                _mayUseTopics(existing[channel.key]))
              id,
      ];
      if (lacking.isNotEmpty) {
        await ref
            .read(channelThumbnailFetcherProvider.notifier)
            .fetchDetails(lacking);
        if (dropped()) return;
        details = ref.read(channelDetailsProvider).value ?? details;
      }
    }

    final pipeline = CategoryPipeline();
    final titles = recentTitlesByChannel(loaded);
    final queue = [
      for (final channel in channels)
        if (needsCategorizing(
          existing[channel.key],
          available: pipeline.tiers,
          hasTopics: details[channel.channelId]?.topicUrls.isNotEmpty ?? false,
        ))
          channel,
    ];
    if (queue.isEmpty) return;

    final progress = ref.read(categorizationProgressProvider.notifier);
    progress.start(queue.length);
    var done = 0;
    try {
      for (final channel in queue) {
        final channelDetails = details[channel.channelId];
        final topicUrls = channelDetails?.topicUrls ?? const <String>[];
        final index = loaded.channelIndexByKey[channel.key];
        final category = await pipeline.categorize((
          key: channel.key,
          topicUrls: topicUrls,
          evidence: ChannelEvidence(
            title: channel.title,
            description: channelDetails?.description,
            topicLabels: [for (final url in topicUrls) topicLabel(url)],
            recentTitles: index == null ? const [] : titles[index],
          ),
        ));
        if (dropped()) return;
        await categories.putIfUndecided(channel.key, category);
        progress.update(++done);
        if (done % _saveEvery == 0) await categories.persist();
      }
    } finally {
      progress.complete();
      if (ref.mounted) await categories.persist();
    }
  }

  /// Whether a channel with the category [existing] could still use its
  /// topics: it has none yet, and the user didn't decide one.
  static bool _mayUseTopics(ChannelCategory? existing) =>
      existing == null ||
      (existing.userDecision == UserDecision.none && existing.path == null);
}
