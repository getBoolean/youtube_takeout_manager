import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel_details.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../domain/categorization_plan.dart';
import '../domain/channel_category.dart';
import '../domain/channel_evidence.dart';
import '../domain/youtube_topics.dart';
import '../data/ai_errors.dart';
import '../data/typesafe_repository.dart';
import 'ai_keys.dart';
import 'ai_tiers.dart';
import 'categorization_inputs.dart';
import 'categorization_progress.dart';
import 'category_pipeline.dart';
import 'channel_categories.dart';

part 'channel_categorizer.g.dart';

/// Saved every so many channels, so a long run's categories survive it
/// being cut short.
const _saveEvery = 10;

/// Channels categorized at once while AI is asked.
const _inFlight = 3;

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
    // A key entered or changed turns its service back on, and has it
    // look at the channels.
    ref.listen(aiKeysProvider, (previous, next) {
      final (before, after) = (previous?.value, next.value);
      if (after == null || before == after) return;
      for (final service in AiService.values) {
        if (before?.keyFor(service) != after.keyFor(service)) {
          ref.read(aiTierStatusProvider.notifier).enable(service);
        }
      }
      _requestRun();
    });
  }

  /// Web: unreachable twice in a row, a service is taken to be blocked by
  /// the browser.
  var _unreachable = 0;

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

    final keys = await ref
        .read(aiKeysProvider.future)
        .catchError((Object _) => AiKeys.none);
    if (dropped()) return;
    final disabled = ref.read(aiTierStatusProvider).disabled;
    final pipeline = CategoryPipeline(
      taxonomy: ref.read(categoryTaxonomyProvider),
      jev: keys.hasJev && !disabled.contains(AiService.jev)
          ? (
              repository: ref.read(typeSafeRepositoryProvider),
              apiKey: keys.keyFor(AiService.jev),
            )
          : null,
    );
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
    var next = 0;
    // Set when an AI step fails: the run stops, and runs again without it
    // when [rerun].
    AiTierFailure? stoppedBy;

    Future<void> worker() async {
      while (next < queue.length && stoppedBy == null && !dropped()) {
        final channel = queue[next++];
        final channelDetails = details[channel.channelId];
        final topicUrls = channelDetails?.topicUrls ?? const <String>[];
        final index = loaded.channelIndexByKey[channel.key];
        final ChannelCategory category;
        try {
          category = await pipeline.categorize((
            key: channel.key,
            topicUrls: topicUrls,
            evidence: ChannelEvidence(
              title: channel.title,
              description: channelDetails?.description,
              topicLabels: [for (final url in topicUrls) topicLabel(url)],
              recentTitles: index == null ? const [] : titles[index],
            ),
          ));
        } on AiTierFailure catch (e) {
          stoppedBy ??= e;
          return;
        }
        if (dropped()) return;
        _unreachable = 0;
        await categories.putIfUndecided(channel.key, category);
        progress.update(++done);
        if (done % _saveEvery == 0) await categories.persist();
      }
    }

    try {
      await Future.wait([
        for (var i = 0; i < (pipeline.tiers.length > 1 ? _inFlight : 1); i++)
          worker(),
      ]);
    } finally {
      progress.complete();
      if (ref.mounted) await categories.persist();
    }
    if (stoppedBy case final failure? when ref.mounted) _stopped(failure);
  }

  /// Says why categorizing stopped: a service that can't work is turned off
  /// and the channels run again without it; a busy one is left for later.
  void _stopped(AiTierFailure failure) {
    final status = ref.read(aiTierStatusProvider.notifier);
    final name = switch (failure.service) {
      AiService.jev => 'Jev',
      AiService.claude => 'Claude',
    };
    final blocked =
        failure.failure is AiUnreachable && kIsWeb && ++_unreachable >= 2;
    switch (failure.failure) {
      case AiKeyRejected():
        status.disable(
          failure.service,
          "$name rejected its API key, so it's off. Check the key in "
          'Takeouts › AI categories.',
        );
      case AiBillingProblem():
        status.disable(
          failure.service,
          "$name's account needs credit, so it's off for now.",
        );
      case AiModelUnavailable():
        status.disable(
          failure.service,
          "$name's model isn't available to this key, so it's off.",
        );
      case _ when blocked:
        status.disable(
          failure.service,
          "$name can't be reached from the web app, so it's off here.",
        );
      default:
        status.note(
          "$name couldn't be asked just now; the rest of the channels are "
          'categorized next time.',
        );
        return;
    }
    // Turned off: the rest go on without it.
    _requestRun();
  }

  /// Whether a channel with the category [existing] could still use its
  /// topics: it has none yet, and the user didn't decide one.
  static bool _mayUseTopics(ChannelCategory? existing) =>
      existing == null ||
      (existing.userDecision == UserDecision.none && existing.path == null);
}
