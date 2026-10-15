import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
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
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_details_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';
import '../domain/categorization_plan.dart';
import '../domain/category_path.dart';
import '../domain/channel_category.dart';
import '../domain/category_prompts.dart';
import '../domain/channel_evidence.dart';
import '../domain/model_capabilities.dart';
import '../domain/name_key.dart';
import '../domain/prompt_videos.dart';
import '../domain/run_estimate.dart';
import '../domain/tag_candidates.dart';
import '../domain/sub_category.dart';
import '../domain/tag_name.dart';
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
import 'categorizing_channels.dart';
import 'category_pipeline.dart';
import 'channel_categories.dart';
import 'channel_tags.dart';
import 'pending_ai_work.dart';
import 'prompt_fingerprints.dart';

part 'channel_categorizer.g.dart';

/// Saved every so many channels, so a long run's categories survive it
/// being cut short.
const _saveEvery = 10;

/// Channels Jev is asked about at once; its pacer keeps them within its
/// limits.
const _preparing = 16;

/// Requests about several channels sent to Claude at once; its pacer keeps
/// them within its limits too.
const _claudeAtOnce = 3;

/// The channels of [queue] in waves of 100, 200, 400, 800 and 1,600, then
/// 2,000 each: the most watched, first, have Claude name the tags the rest
/// mostly reuse through Jev.
Iterable<List<T>> _waves<T>(List<T> queue) sync* {
  var size = 100;
  for (var i = 0; i < queue.length; i += size, size = min(size * 2, 2000)) {
    yield queue.sublist(i, min(i + size, queue.length));
  }
}

/// Groups of channels waiting to go to Claude, taken by whoever asks next;
/// once closed and empty, none more.
class _Groups {
  final _ready = Queue<List<ClaudeTicket>>();
  final _waiting = Queue<Completer<List<ClaudeTicket>?>>();
  var _closed = false;

  void add(List<ClaudeTicket> group) => _waiting.isNotEmpty
      ? _waiting.removeFirst().complete(group)
      : _ready.add(group);

  void close() {
    _closed = true;
    while (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete(null);
    }
  }

  Future<List<ClaudeTicket>?> next() {
    if (_ready.isNotEmpty) return Future.value(_ready.removeFirst());
    if (_closed) return Future.value();
    final waiting = Completer<List<ClaudeTicket>?>();
    _waiting.add(waiting);
    return waiting.future;
  }
}

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
    Timer Function(Duration after, void Function() fire) summaryTimer =
        Timer.new,
    DateTime Function() now = DateTime.now,
  }) : _timer = timer,
       _summaryTimer = summaryTimer,
       _now = now;

  /// Whether this runs in a browser, which can refuse a service outright.
  final bool browser;
  final Timer Function(Duration after, void Function() fire) _timer;

  /// Waits a moment before working out what a run would do, once what it
  /// depends on has stopped changing.
  final Timer Function(Duration after, void Function() fire) _summaryTimer;
  final DateTime Function() _now;

  /// The wait before working out what a run would do.
  Timer? _summaryWait;

  var _generation = 0;
  Future<void>? _running;
  var _again = false;

  /// Whether the user asked for AI ([run]): kept while the run restarts,
  /// such as when subscriptions arrive or a pause ends, and forgotten when
  /// they stop it, another takeout is shown, or a run gets through every
  /// channel. Without it, runs ask YouTube's topics alone.
  var _aiWanted = false;

  /// Whether the run under way asks AI.
  var _runningAi = false;

  /// The pauses kept from before the app was closed, once restored.
  Future<void> _restored = Future.value();

  /// When each paused service resumes, the timers resuming them, and the
  /// notices saying so.
  final _pausedUntil = <AiService, DateTime>{};
  final _resumeTimers = <AiService, Timer>{};
  final _pauseNotices = <AiService, String>{};

  /// The emoji AI gave new sub-categories it suggested, by path, for when
  /// the suggestion is taken.
  final _suggestedEmoji = <CategoryPath, String>{};

  /// The meanings Claude gave tags it named, by their folded names, for
  /// when a suggestion is taken or a result kept.
  final _meanings = <String, String>{};

  /// The emoji AI gave [path], a new sub-category it suggested, if any.
  String? suggestedEmoji(CategoryPath path) => _suggestedEmoji[path];

  /// The meaning Claude gave [tag], a tag it named, if any.
  String? suggestedMeaning(String tag) => _meanings[nameKey(tag)];

  /// Keeps the meanings of the tags [pipeline] named since last asked.
  void _takeMeanings(CategoryPipeline pipeline) {
    for (final (:name, :meaning) in pipeline.takeNamedTags()) {
      if (meaning != null) _meanings[nameKey(name)] = meaning;
    }
  }

  @override
  void build() {
    ref.onDispose(() {
      for (final timer in _resumeTimers.values) {
        timer.cancel();
      }
      _resumeTimers.clear();
      _summaryWait?.cancel();
    });
    // What a run with AI would do, worked out again a moment after what it
    // depends on changes.
    ref.listen(channelCategoriesProvider, (_, _) => _summaryLater());
    ref.listen(tagNamesProvider, (_, _) => _summaryLater());
    ref.listen(aiTierStatusProvider, (_, _) => _summaryLater());
    ref.listen(channelDetailsProvider, (_, _) => _summaryLater());
    _restored = _restorePauses(ref.watch(aiPauseRepositoryProvider));
    // Listened, so the videos kept, a stream, are there to read: one
    // nothing listens to is paused.
    ref.listen(videoMetadataProvider, (_, _) {});
    ref.listen(categorizationInputsProvider, (_, inputs) {
      if (inputs != null) _requestRun();
      _summaryLater();
    }, fireImmediately: true);
    ref.listen(readSessionChannelIdProvider, (previous, next) {
      if (previous == null && next != null) _requestRun();
    });
    // The user's run was for the takeout shown then.
    ref.listen(takeoutSelectionProvider.select((s) => s.value?.takeoutId), (
      previous,
      next,
    ) {
      if (previous != null && previous != next) _aiWanted = false;
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
      _summaryLater();
    });
  }

  /// Works out what a run with AI would do a moment from now, unless the
  /// user's run is going: then once it ends.
  void _summaryLater() {
    _summaryWait?.cancel();
    if (_running != null && _runningAi) return;
    _summaryWait = _summaryTimer(const Duration(milliseconds: 500), () {
      _summaryWait = null;
      unawaited(_summarize().catchError((Object _) {}));
    });
  }

  /// Works out what a run with AI would do now, with the services there are
  /// keys for, or both when there are none, to show what's waiting.
  Future<void> _summarize() async {
    final inputs = ref.read(categorizationInputsProvider);
    final pending = ref.read(pendingAiWorkProvider.notifier);
    if (inputs == null) return pending.set(null);
    final keys = await ref
        .read(aiKeysProvider.future)
        .catchError((Object _) => AiKeys.none);
    final existing = await ref.read(channelCategoriesProvider.future);
    final details = await ref
        .read(channelDetailsProvider.future)
        .catchError((Object _) => const <String, ChannelDetails>{});
    final names = await ref
        .read(tagNamesProvider.future)
        .catchError((Object _) => const <String, TagName>{});
    if (!ref.mounted) return;
    final disabled = ref.read(aiTierStatusProvider).disabled;
    bool on(AiService service) =>
        keys.has(service) && !disabled.contains(service);
    final tiers = {
      CategorizationTier.youtube,
      if (on(AiService.jev) || !keys.hasAny) CategorizationTier.jev,
      if (on(AiService.claude) || !keys.hasAny) CategorizationTier.claude,
    };
    final (:loaded, :subscriptions) = inputs;
    final picks = loaded.promptPicks;
    final videos = ref.read(videoMetadataProvider).value ?? const {};
    final index = TagIndex.of(names, existing, at: _now());
    final fingerprints = {
      for (final MapEntry(:key, :value) in currentPrompts.entries)
        key.name: value,
    };
    final summary = summarizeWork([
      for (final channel in [
        for (final watched in loaded.watchedChannels) watched.channel,
        ...subscriptions.unwatched,
      ])
        if (planWork(
              existing[channel.key],
              available: tiers,
              hasTopics:
                  details[channel.channelId]?.topicUrls.isNotEmpty ?? false,
              fingerprints: fingerprints,
              userTagsChangedAt: index.userTagsChangedAt,
            )
            case final plan)
          (
            plan: plan,
            existing: existing[channel.key],
            evidenceChars: plan.work == ChannelWork.none && !plan.checkTags
                ? 0
                : _evidenceSizeOf(channel, loaded, details, picks, videos),
          ),
    ]);
    if (ref.mounted) pending.set(summary);
  }

  /// Categorizes with AI, as the user asked: Jev and Claude as the keys
  /// allow, going on from where the last run left off. While a service
  /// asked to wait, it starts when the wait ends.
  void run() {
    if (_aiWanted && _runningAi) return;
    if (!_aiWanted) ref.read(claudeUsageProvider.notifier).reset();
    _aiWanted = true;
    _requestRun();
  }

  /// Stops the user's run: nothing more is asked, and the answers already
  /// asked for still land. A wait ending afterwards starts nothing.
  void stop() {
    _aiWanted = false;
    if (_running == null || !_runningAi) return;
    _again = false;
    _generation++;
    ref.read(categorizationProgressProvider.notifier).stopping();
  }

  /// Runs now, or again once the run under way ends.
  void _requestRun() {
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
    _runningAi = _aiWanted;

    await _restored;
    // A wait a service asked for holds AI, not YouTube's topics.
    final ai = _aiWanted && _pausedUntil.isEmpty;
    _runningAi = ai;
    final progress = ref.read(categorizationProgressProvider.notifier);
    if (ai && ref.mounted) progress.start(0, ai: true);
    var finished = false;
    try {
      finished = await _categorize(ai: ai, dropped: dropped);
    } finally {
      if (ref.mounted && ref.read(categorizationProgressProvider).running) {
        progress.complete(interrupted: ai && !finished);
      }
      if (ai && finished && ref.mounted) _aiWanted = false;
      if (ai && ref.mounted) {
        // Held while the run went: worked out again now.
        _runningAi = false;
        _summaryLater();
      }
    }
  }

  /// One run: YouTube's topics, and when [ai], Jev and Claude too. True
  /// when it got through every channel it had to.
  Future<bool> _categorize({
    required bool ai,
    required bool Function() dropped,
  }) async {
    if (dropped()) return false;
    final inputs = ref.read(categorizationInputsProvider);
    if (inputs == null) return false;
    final categories = ref.read(channelCategoriesProvider.notifier);
    final existing = await ref.read(channelCategoriesProvider.future);
    var details = await ref
        .read(channelDetailsProvider.future)
        .catchError((Object _) => const <String, ChannelDetails>{});
    if (dropped()) return false;

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
        if (dropped()) return false;
        details = ref.read(channelDetailsProvider).value ?? details;
      }
    }

    CategoryPipeline pipeline;
    if (!ai) {
      pipeline = await _pipeline(withJev: false, withClaude: false);
    } else {
      try {
        pipeline = await _pipeline();
      } on AiTierFailure catch (e) {
        // Claude's model couldn't be looked up. Turned off, it all runs
        // again without Claude; paused, it waits; otherwise this run goes on
        // without Claude.
        if (!ref.mounted) return false;
        _stopped(e);
        final off = ref.read(aiTierStatusProvider).disabled.contains(e.service);
        if (off || _pausedUntil.isNotEmpty) return false;
        pipeline = await _pipeline(withClaude: false);
      }
    }
    if (dropped()) return false;
    // Only AI is told about the videos watched.
    final picks = ai ? loaded.promptPicks : const <PromptPicks>[];
    final fingerprints = {
      for (final MapEntry(:key, :value) in currentPrompts.entries)
        key.name: value,
    };
    final tags = TagIndex.of(
      await ref
          .read(tagNamesProvider.future)
          .catchError((Object _) => const <String, TagName>{}),
      existing,
      at: _now(),
    );
    if (dropped()) return false;
    final queue = <(HistoryChannel, WorkPlan)>[];
    var redo = false;
    final unplaced = <String, ChannelCategory>{};
    final now = DateTime.now().toUtc();
    for (final channel in channels) {
      final hasTopics =
          details[channel.channelId]?.topicUrls.isNotEmpty ?? false;
      final plan = planWork(
        existing[channel.key],
        available: pipeline.tiers,
        hasTopics: hasTopics,
        fingerprints: fingerprints,
        userTagsChangedAt: tags.userTagsChangedAt,
      );
      if (plan.work != ChannelWork.none || plan.checkTags) {
        queue.add((channel, plan));
        redo = redo || plan.redo;
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
    if (queue.isEmpty) return !dropped();

    // Signed in, the descriptions of the videos AI is told about that
    // aren't kept yet are fetched first, as topics are.
    if (ai && ref.read(readSessionChannelIdProvider) != null) {
      final watches = loaded.history.watches;
      final videoIds = {
        for (final (channel, _) in queue)
          if (loaded.channelIndexByKey[channel.key] case final i?
              when i < picks.length)
            for (final w in picks[i].described) ?watches[w].videoId,
      };
      if (videoIds.isNotEmpty) {
        await ref
            .read(videoDetailsFetcherProvider.notifier)
            .fetch(videoIds, stop: dropped)
            .catchError((Object _) {});
        if (dropped()) return false;
      }
    }
    final videos = ai
        ? await ref
              .read(videoMetadataProvider.future)
              .catchError((Object _) => const <String, Video>{})
        : const <String, Video>{};
    if (dropped()) return false;

    final progress = ref.read(categorizationProgressProvider.notifier);
    final categorizing = ref.read(categorizingChannelsProvider.notifier);
    progress.start(queue.length, redo: redo, ai: ai);
    var done = 0;
    // Set when an AI step fails: the run stops, and runs again without it
    // when [rerun].
    AiTierFailure? stoppedBy;
    // Set when something else goes wrong: the run stops, saying so.
    Object? crash;
    bool halted() => stoppedBy != null || crash != null || dropped();

    /// Counts [key]'s channel done, saving every so often.
    Future<void> finished(String key) async {
      if (ref.mounted) categorizing.remove(key);
      if (dropped()) return;
      progress.update(++done);
      if (done % _saveEvery == 0) await categories.persist();
    }

    /// Keeps [result] for [key]'s channel: still right for it when the run
    /// was dropped, and paid for, so kept either way.
    Future<void> keep(String key, ChannelCategory result) async {
      if (!ref.mounted) return;
      await _keepLearned(pipeline);
      _takeMeanings(pipeline);
      var category = result;
      if (category.tags.isNotEmpty) {
        category = category.copyWith(
          tags: await ref.read(tagNamesProvider.notifier).resolveNamed([
            for (final tag in category.tags)
              (name: tag, meaning: suggestedMeaning(tag)),
          ], NameOrigin.ai),
        );
      }
      await categories.putAiResult(key, category);
      await finished(key);
    }

    try {
      for (final wave in _waves(queue)) {
        if (halted()) break;
        // Made again for each wave: the tags Claude named in the waves
        // before are offered to Jev in this one.
        final index = TagIndex.of(
          ref.read(tagNamesProvider).value ?? const {},
          ref.read(channelCategoriesProvider).value ?? existing,
          at: _now(),
        );
        final groups = _Groups();
        final waiting = {
          for (final ask in ClaudeAsk.values) ask: <ClaudeTicket>[],
        };
        // A full group goes to Claude at once; the rest when the wave's
        // channels are all prepared.
        void send(ClaudeAsk ask, {bool rest = false}) {
          final tickets = waiting[ask]!;
          if (tickets.isEmpty || (!rest && tickets.length < maxGroupChannels)) {
            return;
          }
          groups.add([...tickets]);
          tickets.clear();
        }

        Future<void> asker() async {
          for (
            var group = await groups.next();
            group != null;
            group = await groups.next()
          ) {
            // Once stopped, what's waiting is never sent.
            if (halted()) continue;
            try {
              await pipeline.askClaude(
                group,
                stopped: halted,
                tags: index,
                onResult: keep,
              );
            } on AiTierFailure catch (e) {
              stoppedBy ??= e;
            } on Object catch (e) {
              crash ??= e;
            }
          }
        }

        var next = 0;
        Future<void> preparer() async {
          while (next < wave.length && !halted()) {
            final (channel, plan) = wave[next++];
            final key = channel.key;
            categorizing.add(key);
            final input = channelInputFor(
              channel,
              loaded,
              details,
              picks,
              videos,
            );
            ChannelCategory? latest() =>
                ref.read(channelCategoriesProvider).value?[key] ??
                existing[key];
            Future<void> check(Map<String, double> yes, DateTime at) =>
                categories.checkTags(
                  key,
                  yes,
                  // The tags as they are now: one deleted, or left without
                  // a meaning, while Jev was asked, isn't given.
                  ref.read(tagNamesProvider).value ?? index.names,
                  at: at,
                );
            try {
              // Claude only adds to the tags: Jev checks the user's first.
              if (plan.work == ChannelWork.claudeTags && plan.checkTags) {
                if (await pipeline.prepare(
                      input,
                      (work: ChannelWork.none, redo: false, checkTags: true),
                      existing: latest(),
                      tags: index,
                    )
                    case Checked(:final yes, :final at)) {
                  if (!ref.mounted) return;
                  await check(yes, at);
                }
                if (halted()) continue;
              }
              final prepared = await pipeline.prepare(
                input,
                plan,
                existing: latest(),
                tags: index,
              );
              switch (prepared) {
                case Settled(:final result):
                  await keep(key, result);
                case Checked(:final yes, :final at):
                  if (!ref.mounted) return;
                  await check(yes, at);
                  await finished(key);
                case NeedsClaude(:final ticket):
                  waiting[ticket.ask]!.add(ticket);
                  send(ticket.ask);
              }
            } on AiTierFailure catch (e) {
              stoppedBy ??= e;
            } on Object catch (e) {
              crash ??= e;
            }
          }
        }

        final askers = [for (var i = 0; i < _claudeAtOnce; i++) asker()];
        await Future.wait([
          for (var i = 0; i < (ai ? _preparing : 1); i++) preparer(),
        ]);
        for (final ask in ClaudeAsk.values) {
          send(ask, rest: true);
        }
        groups.close();
        await Future.wait(askers);
        // Channels whose tickets were never sent aren't being asked about.
        if (ref.mounted) {
          for (final (channel, _) in wave) {
            categorizing.remove(channel.key);
          }
        }
      }
    } finally {
      if (ref.mounted) await categories.persist();
    }
    if (!ref.mounted) return false;
    if (crash case final e?) {
      _crashed(e);
      return false;
    }
    if (stoppedBy case final failure?) {
      _stopped(failure);
      return false;
    }
    return !dropped();
  }

  /// Stops the run under way, if any, and waits for it to end: answers
  /// already asked for still land, but nothing more is asked.
  Future<void> stopRun() async {
    _aiWanted = false;
    _again = false;
    _generation++;
    await _running;
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
    final categories = await ref.read(channelCategoriesProvider.future);
    final current = categories[channel.key];
    final names = await ref
        .read(tagNamesProvider.future)
        .catchError((Object _) => const <String, TagName>{});
    final suggestion = await pipeline.suggestInstead(
      channelInputFor(
        channel,
        loaded,
        details,
        loaded.promptPicks,
        ref.read(videoMetadataProvider).value ?? const {},
      ),
      current?.path,
      tags: TagIndex.of(names, categories, at: _now()),
    );
    for (final (:path, :emoji) in pipeline.takeLearned()) {
      if (emoji != null) _suggestedEmoji[path] = emoji;
    }
    _takeMeanings(pipeline);
    return suggestion;
  }

  /// A pipeline with the steps there are keys for, Jev only [withJev] and
  /// Claude only [withClaude], and every category. Throws an
  /// [AiTierFailure] when Claude's model can't be used.
  Future<CategoryPipeline> _pipeline({
    bool withJev = true,
    bool withClaude = true,
  }) async {
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
      jev: withJev && on(AiService.jev)
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
      onUsage: (input, output) {
        if (ref.mounted) {
          ref.read(claudeUsageProvider.notifier).add(input, output);
        }
      },
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

  /// About how much evidence AI would be told about [channel], worked out
  /// without making it, as [channelInputFor] would: quick enough for every
  /// channel each time what a run would do is worked out.
  static int _evidenceSizeOf(
    HistoryChannel channel,
    LoadedHistory loaded,
    Map<String, ChannelDetails> details,
    List<PromptPicks> picks,
    Map<String, Video> videos,
  ) {
    final channelDetails = details[channel.channelId];
    final index = loaded.channelIndexByKey[channel.key];
    final PromptPicks channelPicks = index == null || index >= picks.length
        ? (titles: const [], described: const [])
        : picks[index];
    final watches = loaded.history.watches;
    return evidenceSize(
      title: channel.title,
      description: channelDetails?.description,
      topics: channelDetails?.topicUrls.length ?? 0,
      titles: [for (final i in channelPicks.titles) watches[i].title],
      described: [
        for (final i in channelPicks.described)
          (
            title: watches[i].title,
            description: videos[watches[i].videoId]?.description,
          ),
      ],
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
      // Without Jev, Claude would take every channel's tags: the user's run
      // ends. Without Claude, the rest go on with Jev.
      if (service == AiService.jev) _aiWanted = false;
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
        _aiWanted = false;
        status.note(
          "$name couldn't be reached, so categorizing with AI stopped; "
          'continue it to try again.',
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
        _aiWanted = false;
        status.note(
          "$name gave no usable answer, so categorizing with AI stopped; "
          'continue it to try again.',
        );
    }
  }

  /// Says categorizing stopped for [error], which no AI service explains,
  /// never quoting a key.
  void _crashed(Object error) {
    _aiWanted = false;
    final keys = ref.read(aiKeysProvider).value ?? AiKeys.none;
    var failure = aiFailureOf(error, secret: keys.keyFor(AiService.jev));
    failure = aiFailureOf(failure, secret: keys.keyFor(AiService.claude));
    ref
        .read(aiTierStatusProvider.notifier)
        .note('Categorizing stopped after an error: ${failure.message}');
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

/// What's known about [channel]: its topics and description, and the
/// titles of videos watched from it that [picks] has for it, some with
/// their descriptions from [videos].
ChannelInput channelInputFor(
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
