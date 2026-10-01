import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel_details.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';
import '../domain/categorization_plan.dart';
import '../domain/category_path.dart';
import '../domain/channel_category.dart';
import '../domain/channel_evidence.dart';
import '../domain/model_capabilities.dart';
import '../domain/prompt_videos.dart';
import '../domain/sub_category.dart';
import '../domain/youtube_topics.dart';
import '../data/ai_errors.dart';
import '../data/ai_pause_repository.dart';
import '../data/anthropic_repository.dart';
import '../data/model_capabilities_repository.dart';
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

/// How long categorizing pauses for a busy service that didn't say.
const _defaultPause = Duration(minutes: 5);

/// How long categorizing pauses at least: a service still refusing after
/// its stated waits isn't asked again straight away.
const _shortestPause = Duration(minutes: 1);

/// Categorizes the channels watched and subscribed to, the most watched
/// first, once the history screen has been opened. Signed in, it first asks
/// YouTube for the topics of channels it doesn't know them for. A category
/// the user accepted or denied is never replaced. Starts over when the
/// history, subscriptions or sign-in change, dropping the run under way.
/// A service that asks to wait pauses categorizing, even across launches,
/// and it resumes itself.
///
/// A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class ChannelCategorizer extends _$ChannelCategorizer {
  ChannelCategorizer({
    this.browser = kIsWeb,
    Timer Function(Duration after, void Function() fire) timer = Timer.new,
    DateTime Function() now = DateTime.now,
  }) : _timer = timer,
       _now = now;

  /// Whether this runs in a browser, which can refuse a service outright.
  final bool browser;
  final Timer Function(Duration after, void Function() fire) _timer;
  final DateTime Function() _now;

  var _generation = 0;
  Future<void>? _running;
  var _again = false;

  /// The pauses kept from before the app was closed, once restored.
  Future<void> _restored = Future.value();

  /// When each paused service resumes, the timers resuming them, and the
  /// notices saying so.
  final _pausedUntil = <AiService, DateTime>{};
  final _resumeTimers = <AiService, Timer>{};
  final _pauseNotices = <AiService, String>{};

  @override
  void build() {
    ref.onDispose(() {
      for (final timer in _resumeTimers.values) {
        timer.cancel();
      }
      _resumeTimers.clear();
    });
    _restored = _restorePauses(ref.watch(aiPauseRepositoryProvider));
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
          // A pause was for the key before; the keys loading at launch
          // aren't a change.
          if (before != null) _endPause(service);
        }
      }
      _requestRun();
    });
  }

  /// Runs now, or again once the run under way ends; while paused, not
  /// until the pause ends.
  void _requestRun() {
    if (_pausedUntil.isNotEmpty) return;
    if (_running != null) {
      _again = true;
      _generation++;
      return;
    }
    _running = _run()
        .catchError((Object e) {
          if (ref.mounted) _crashed(e);
        })
        .whenComplete(() {
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

    await _restored;
    if (dropped() || _pausedUntil.isNotEmpty) return;
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

    CategoryPipeline pipeline;
    try {
      pipeline = await _pipeline();
    } on AiTierFailure catch (e) {
      // Claude's model couldn't be looked up. Turned off, it all runs again
      // without Claude; paused, it waits; otherwise this run goes on
      // without Claude.
      if (!ref.mounted) return;
      _stopped(e);
      final off = ref.read(aiTierStatusProvider).disabled.contains(e.service);
      if (off || _pausedUntil.isNotEmpty) return;
      pipeline = await _pipeline(withClaude: false);
    }
    if (dropped()) return;
    final picks = pickPromptVideos(loaded);
    final videos = ref.read(videoMetadataProvider).value ?? const {};
    final queue = <HistoryChannel>[];
    final unplaced = <String, ChannelCategory>{};
    final now = DateTime.now().toUtc();
    for (final channel in channels) {
      final hasTopics =
          details[channel.channelId]?.topicUrls.isNotEmpty ?? false;
      if (needsCategorizing(
        existing[channel.key],
        available: pipeline.tiers,
        hasTopics: hasTopics,
      )) {
        queue.add(channel);
      } else if (existing[channel.key] == null) {
        // Nothing to go on yet: uncategorized, and looked at again once
        // topics or AI come.
        unplaced[channel.key] = ChannelCategory(
          tried: pipeline.tiers,
          hadTopics: hasTopics,
          decidedAt: now,
        );
      }
    }
    if (unplaced.isNotEmpty) {
      await categories.addMissing(unplaced);
      if (ref.mounted) await categories.persist();
    }
    if (queue.isEmpty) return;

    final progress = ref.read(categorizationProgressProvider.notifier);
    progress.start(queue.length);
    var done = 0;
    var next = 0;
    // Set when an AI step fails: the run stops, and runs again without it
    // when [rerun].
    AiTierFailure? stoppedBy;
    // Set when something else goes wrong: the run stops, saying so.
    Object? crash;

    Future<void> worker() async {
      try {
        while (next < queue.length &&
            stoppedBy == null &&
            crash == null &&
            !dropped()) {
          final channel = queue[next++];
          final ChannelCategory category;
          try {
            category = await pipeline.categorize(
              _inputFor(channel, loaded, details, picks, videos),
            );
          } on AiTierFailure catch (e) {
            stoppedBy ??= e;
            return;
          }
          if (!ref.mounted) return;
          // Still right for its channel when the run was dropped, and paid
          // for: kept either way.
          await _keepLearned(pipeline);
          await categories.putAiResult(channel.key, category);
          if (dropped()) return;
          progress.update(++done);
          if (done % _saveEvery == 0) await categories.persist();
        }
      } on Object catch (e) {
        crash ??= e;
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
    if (!ref.mounted) return;
    if (crash case final e?) {
      _crashed(e);
    } else if (stoppedBy case final failure?) {
      _stopped(failure);
    }
  }

  /// Whether AI can be asked for another category: there's a key for Jev
  /// or Claude, and it isn't turned off.
  bool get canAskAi {
    final keys = ref.read(aiKeysProvider).value ?? AiKeys.none;
    final disabled = ref.read(aiTierStatusProvider).disabled;
    return AiService.values.any(
      (service) => keys.has(service) && !disabled.contains(service),
    );
  }

  /// Another category for [channel], from AI told the one it has is wrong.
  /// Throws an [AiTierFailure] when the AI can't be asked.
  Future<ChannelCategory> suggest(HistoryChannel channel) async {
    // A pause kept from before is the services' too: asking fails at once
    // when it's far off.
    await _restored;
    final pipeline = await _pipeline();
    final LoadedHistory loaded =
        ref.read(categorizationInputsProvider)?.loaded ??
        ref.read(takeoutHistoryProvider).value ??
        LoadedHistory.empty;
    final details = await ref
        .read(channelDetailsProvider.future)
        .catchError((Object _) => const <String, ChannelDetails>{});
    final current = (await ref.read(
      channelCategoriesProvider.future,
    ))[channel.key];
    return pipeline.suggestInstead(
      _inputFor(
        channel,
        loaded,
        details,
        pickPromptVideos(loaded),
        ref.read(videoMetadataProvider).value ?? const {},
      ),
      current?.path,
    );
  }

  /// Makes [suggestion] [channel]'s category, as the user chose, keeping a
  /// new sub-category it names.
  Future<void> accept(
    HistoryChannel channel,
    ChannelCategory suggestion,
  ) async {
    await ref.read(customCategoriesProvider.future);
    // As spelled where it's there already, else added.
    final taxonomy = ref.read(categoryTaxonomyProvider);
    var path = suggestion.path;
    if (path != null) {
      path = taxonomy.find(path.parent, path.child) ?? path;
      if (path.child case final child? when !taxonomy.contains(path)) {
        path = CategoryPath(
          path.parent,
          await ref
              .read(customCategoriesProvider.notifier)
              .add(path.parent, child),
        );
      }
    }
    await ref
        .read(channelCategoriesProvider.notifier)
        .decide(
          channel.key,
          suggestion.copyWith(
            path: path,
            userDecision: UserDecision.accepted,
            decidedAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Keeps [channel]'s category as it is, as the user chose: nothing
  /// replaces it.
  Future<void> deny(HistoryChannel channel) async {
    final now = DateTime.now().toUtc();
    final current = (await ref.read(
      channelCategoriesProvider.future,
    ))[channel.key];
    await ref
        .read(channelCategoriesProvider.notifier)
        .decide(
          channel.key,
          (current ?? ChannelCategory(decidedAt: now)).copyWith(
            userDecision: UserDecision.denied,
            decidedAt: now,
          ),
        );
  }

  /// A pipeline with the steps there are keys for, Claude only [withClaude],
  /// and every category. Throws an [AiTierFailure] when Claude's model can't
  /// be used.
  Future<CategoryPipeline> _pipeline({bool withClaude = true}) async {
    final keys = await ref
        .read(aiKeysProvider.future)
        .catchError((Object _) => AiKeys.none);
    await ref
        .read(customCategoriesProvider.future)
        .catchError((Object _) => const <String, List<SubCategory>>{});
    final disabled = ref.read(aiTierStatusProvider).disabled;
    bool on(AiService service) =>
        keys.has(service) && !disabled.contains(service);
    final categories = await ref
        .read(channelCategoriesProvider.future)
        .catchError((Object _) => const <String, ChannelCategory>{});
    return CategoryPipeline(
      taxonomy: ref.read(categoryTaxonomyProvider),
      usage: _usage(categories),
      jev: on(AiService.jev)
          ? (
              repository: ref.read(typeSafeRepositoryProvider),
              apiKey: keys.keyFor(AiService.jev),
            )
          : null,
      claude: withClaude && on(AiService.claude)
          ? (
              repository: ref.read(anthropicRepositoryProvider),
              apiKey: keys.keyFor(AiService.claude),
              model: await _claudeModel(keys.keyFor(AiService.claude)),
            )
          : null,
    );
  }

  /// How many channels have each category.
  static Map<CategoryPath, int> _usage(
    Map<String, ChannelCategory> categories,
  ) {
    final usage = <CategoryPath, int>{};
    for (final category in categories.values) {
      if (category.path case final path?) {
        usage[path] = (usage[path] ?? 0) + 1;
      }
    }
    return usage;
  }

  /// What the Claude model in use can do: as kept, else asked for with
  /// [apiKey] and kept. Throws an [AiTierFailure] when it can't be asked,
  /// or the model can't answer in shapes.
  Future<ModelCapabilities> _claudeModel(String apiKey) async {
    final kept = ref.read(modelCapabilitiesRepositoryProvider);
    var model = await kept.load(anthropicModel);
    if (model == null) {
      try {
        model = await ref
            .read(anthropicRepositoryProvider)
            .capabilities(apiKey: apiKey, model: anthropicModel);
      } on AiFailure catch (e) {
        throw AiTierFailure(AiService.claude, e);
      }
      await kept.save(model);
    }
    if (!model.structuredOutputs) {
      throw AiTierFailure(
        AiService.claude,
        AiModelUnavailable(
          "$anthropicModel can't answer in the shape categorizing needs.",
        ),
      );
    }
    return model;
  }

  /// What's known about [channel]: its topics and description, and the
  /// titles of videos watched from it that [picks] has for it, some with
  /// their descriptions from [videos].
  static ChannelInput _inputFor(
    HistoryChannel channel,
    LoadedHistory loaded,
    Map<String, ChannelDetails> details,
    List<PromptPicks> picks,
    Map<String, Video> videos,
  ) {
    final channelDetails = details[channel.channelId];
    final topicUrls = channelDetails?.topicUrls ?? const <String>[];
    final index = loaded.channelIndexByKey[channel.key];
    final PromptPicks channelPicks = index == null || index >= picks.length
        ? (titles: const [], described: const [])
        : picks[index];
    final watches = loaded.history.watches;
    return (
      key: channel.key,
      topicUrls: topicUrls,
      evidence: buildEvidence(
        title: channel.title,
        description: channelDetails?.description,
        topicLabels: [for (final url in topicUrls) topicLabel(url)],
        picks: channelPicks,
        watches: watches,
        descriptions: {
          for (final id in [
            for (final i in channelPicks.described) ?watches[i].videoId,
          ])
            id: videos[id]?.description,
        },
      ),
    );
  }

  /// Keeps the sub-categories [pipeline] learned, for later channels.
  Future<void> _keepLearned(CategoryPipeline pipeline) async {
    for (final (:path, :emoji) in pipeline.takeLearned()) {
      await ref
          .read(customCategoriesProvider.notifier)
          .add(path.parent, path.child!, emoji: emoji);
    }
  }

  /// Says why categorizing stopped: a service that can't work is turned off
  /// and the channels run again without it; a busy one pauses categorizing
  /// until it can be asked again; otherwise it's left for next time.
  void _stopped(AiTierFailure failure) {
    final status = ref.read(aiTierStatusProvider.notifier);
    final service = failure.service;
    final name = _nameOf(service);
    void off(String notice) {
      status.disable(service, notice);
      // Turned off: the rest go on without it.
      _requestRun();
    }

    switch (failure.failure) {
      case AiKeyRejected():
        off(
          "$name rejected its API key, so it's off. Check the key in "
          'Takeouts › AI categories.',
        );
      case AiBillingProblem(:final message):
        off(
          "$name's account can't pay for more, so it's off for now: $message",
        );
      case AiModelUnavailable(:final message):
        off("$name's model can't be used, so it's off: $message");
      case AiBadRequest(:final message):
        // A request it can't read is one every channel's would be.
        off("$name turned down the request ($message), so it's off for now.");
      case AiUnexpected(:final message):
        off("Something went wrong asking $name, so it's off for now: $message");
      case AiUnreachable() when browser:
        // In a browser, a service still unreachable after its retries is
        // taken to be refused by the browser: asking again would fail the
        // same way.
        off("$name can't be reached from the web app, so it's off here.");
      case AiUnreachable():
        status.note(
          "$name couldn't be reached; the rest of the channels are "
          'categorized next time.',
        );
      case AiRateLimited(:final resumeAt) || AiOverloaded(:final resumeAt):
        final now = _now();
        final soonest = now.add(_shortestPause);
        final until = switch (resumeAt) {
          null => now.add(_defaultPause),
          final at when at.isBefore(soonest) => soonest,
          final at => at,
        };
        _hold(service, until);
        unawaited(
          ref
              .read(aiPauseRepositoryProvider)
              .save(service, until, since: _now())
              .catchError((Object _) {}),
        );
      case AiNoAnswer():
        status.note(
          "$name gave no usable answer; the rest of the channels are "
          'categorized next time.',
        );
    }
  }

  /// Says categorizing stopped for [error], which no AI service explains,
  /// never quoting a key.
  void _crashed(Object error) {
    final keys = ref.read(aiKeysProvider).value ?? AiKeys.none;
    var failure = aiFailureOf(error, secret: keys.keyFor(AiService.jev));
    failure = aiFailureOf(failure, secret: keys.keyFor(AiService.claude));
    ref
        .read(aiTierStatusProvider.notifier)
        .note(
          'Categorizing stopped after an error, and starts again next time: '
          '${failure.message}',
        );
  }

  /// Pauses categorizing, and [service]'s requests, until [until], saying
  /// so, and resumes then.
  void _hold(AiService service, DateTime until) {
    _pausedUntil[service] = until;
    switch (service) {
      case AiService.jev:
        ref.read(typeSafeRepositoryProvider).pauseUntil(until);
      case AiService.claude:
        ref.read(anthropicRepositoryProvider).pauseUntil(until);
    }
    _resumeTimers.remove(service)?.cancel();
    final left = until.difference(_now());
    _resumeTimers[service] = _timer(left.isNegative ? Duration.zero : left, () {
      _endPause(service);
      _requestRun();
    });
    final notice =
        '${_nameOf(service)} asked to wait, so categorizing pauses; it '
        'resumes at ${timeOfDay(until)}.';
    _pauseNotices[service] = notice;
    ref.read(aiTierStatusProvider.notifier).note(notice);
  }

  /// Ends [service]'s pause, if it has one, forgetting it and its notice.
  void _endPause(AiService service) {
    if (_pausedUntil.remove(service) == null) return;
    _resumeTimers.remove(service)?.cancel();
    switch (service) {
      case AiService.jev:
        ref.read(typeSafeRepositoryProvider).resume();
      case AiService.claude:
        ref.read(anthropicRepositoryProvider).resume();
    }
    unawaited(
      ref
          .read(aiPauseRepositoryProvider)
          .clear(service)
          .catchError((Object _) {}),
    );
    final notice = _pauseNotices.remove(service);
    final status = ref.read(aiTierStatusProvider);
    if (notice != null && status.notice == notice) {
      ref.read(aiTierStatusProvider.notifier).dismiss();
    }
  }

  /// Holds the services still paused from before the app was closed for
  /// the time left, and forgets the pauses that have passed.
  Future<void> _restorePauses(AiPauseRepository pauses) async {
    final now = _now();
    final Map<AiService, DateTime> kept;
    try {
      kept = await pauses.load(now: now);
    } on Object {
      return;
    }
    if (!ref.mounted) return;
    for (final MapEntry(key: service, value: until) in kept.entries) {
      if (until.isAfter(now)) {
        _hold(service, until);
      } else {
        unawaited(pauses.clear(service).catchError((Object _) {}));
      }
    }
  }

  static String _nameOf(AiService service) => switch (service) {
    AiService.jev => 'Jev',
    AiService.claude => 'Claude',
  };

  /// Whether a channel with the category [existing] could still use its
  /// topics: it has none yet, and the user didn't decide one.
  static bool _mayUseTopics(ChannelCategory? existing) =>
      existing == null ||
      (existing.userDecision == UserDecision.none && existing.path == null);
}
