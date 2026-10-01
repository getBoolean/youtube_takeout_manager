import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import '../data/typesafe_repository.dart';
import '../domain/category_path.dart';
import '../domain/category_prompts.dart';
import '../domain/channel_evidence.dart';
import '../domain/prompt_videos.dart';
import '../domain/youtube_taxonomy.dart';
import '../domain/youtube_topics.dart';
import 'jev_prompts.dart';

/// A step that asks AI, whose prompt has a fingerprint.
enum PromptStep { jevCheck, jevPick, jevNameCheck, claudeCategory, claudeTags }

/// What makes the prompts: how videos are picked, what the evidence holds,
/// and each request. Tests swap one to see its fingerprint change.
class PromptBuilders {
  final List<PromptPicks> Function(LoadedHistory loaded) pickVideos;
  final ChannelEvidence Function({
    required String title,
    String? description,
    List<String> topicLabels,
    required PromptPicks picks,
    required List<WatchEntry> watches,
    required Map<String, String?> descriptions,
  })
  evidence;
  final ClaudeRequest Function(
    ChannelEvidence evidence,
    Taxonomy taxonomy, {
    List<String> knownTags,
    CategoryPath? inaccurate,
  })
  claudeCategory;
  final ClaudeRequest Function(
    ChannelEvidence evidence,
    CategoryPath category, {
    List<String> knownTags,
  })
  claudeTags;
  final JevNoul Function(CategoryPath candidate) jevFit;
  final JevChoice Function(Taxonomy taxonomy, {CategoryPath? exclude})
  jevParent;
  final JevChoice Function(
    String parent,
    Map<String, String> children, {
    required bool withGeneral,
  })
  jevChild;
  final JevChoice Function(String parent, Map<String, String> existing) jevSame;
  final Map<String, Object> Function({
    required String proposed,
    required String parent,
    required String reason,
    required String channel,
  })
  jevSameStateOf;

  const PromptBuilders({
    this.pickVideos = pickPromptVideos,
    this.evidence = buildEvidence,
    this.claudeCategory = claudeCategoryRequest,
    this.claudeTags = claudeTagsRequest,
    this.jevFit = jevFitQuestion,
    this.jevParent = jevParentQuestion,
    this.jevChild = jevChildQuestion,
    this.jevSame = jevSameQuestion,
    this.jevSameStateOf = jevSameState,
  });
}

/// Each step's fingerprint: a hash of its prompt and answer shape, built
/// with [builders] for a fixed sample channel against a fixed taxonomy, so
/// a change to the wording, the shape, or what evidence goes in (how the
/// videos are picked among them) changes it without anyone bumping a
/// number. Which model answers isn't part of it.
Map<PromptStep, String> fingerprintPrompts([
  PromptBuilders builders = const PromptBuilders(),
]) {
  final loaded = LoadedHistory.of(_sampleHistory());
  final picks = builders.pickVideos(
    loaded,
  )[loaded.channelIndexByKey['name:$_channel']!];
  final watches = loaded.history.watches;
  final evidence = builders.evidence(
    title: _channel,
    description: 'Speedruns of classic games, explained one trick at a time.',
    topicLabels: [for (final url in _topics) topicLabel(url)],
    picks: picks,
    watches: watches,
    descriptions: {
      for (final id in [for (final i in picks.described) ?watches[i].videoId])
        id:
            'Run $id of the route, frame by frame. https://example.com/$id '
            '#speedrun #retro\n0:00 Start\n12:34 Finish',
    },
  );
  final state = evidence.toState();
  final gaming = jevOptionKeys(_taxonomy.childrenOf('Gaming'));
  final requests = <PromptStep, Object>{
    PromptStep.jevCheck: {
      'state': state,
      'questions': {
        'fits_0': builders
            .jevFit(const CategoryPath('Gaming', 'Action'))
            .toJson(),
        'parent': builders.jevParent(_taxonomy).toJson(),
      },
    },
    PromptStep.jevPick: {
      'state': state,
      'questions': {
        'child': builders
            .jevChild('Gaming', gaming, withGeneral: true)
            .toJson(),
      },
    },
    PromptStep.jevNameCheck: {
      'state': builders.jevSameStateOf(
        proposed: 'Speed running',
        parent: 'Gaming',
        reason: 'Races through classic games',
        channel: _channel,
      ),
      'questions': {'same': builders.jevSame('Gaming', gaming).toJson()},
    },
    PromptStep.claudeCategory: _claude(
      builders.claudeCategory(evidence, _taxonomy, knownTags: _knownTags),
    ),
    PromptStep.claudeTags: _claude(
      builders.claudeTags(
        evidence,
        const CategoryPath('Gaming', 'Speedruns'),
        knownTags: _knownTags,
      ),
    ),
  };
  return {
    for (final MapEntry(key: step, value: request) in requests.entries)
      step: sha256
          .convert(utf8.encode(jsonEncode(request)))
          .toString()
          .substring(0, 16),
  };
}

/// The prompts' fingerprints now, worked out once.
final Map<PromptStep, String> currentPrompts = fingerprintPrompts();

Map<String, Object> _claude(ClaudeRequest request) => {
  'system': request.system,
  'user': request.user,
  'schema': request.schema,
};

const _channel = 'Sample Speedruns';
const _topics = [
  'https://en.wikipedia.org/wiki/Action_game',
  'https://en.wikipedia.org/wiki/Video_game_culture',
];
const _knownTags = ['Mario Kart World', 'ASMR', 'Blue Archive'];
final _taxonomy = youtubeTaxonomy.withCustom({
  'Gaming': ['Speedruns'],
  'Knowledge': ['Space'],
});

/// A channel watched over nearly six years: 90 videos, 12 of them watched
/// two to six times, so a change to how videos are picked shows.
TakeoutHistory _sampleHistory() {
  final start = DateTime.utc(2019);
  WatchEntry watch(int video, DateTime time) => WatchEntry(
    time: time,
    kind: WatchKind.video,
    title: 'Sample run $video: any% route, explained',
    url: 'https://www.youtube.com/watch?v=sample$video',
    channelTitle: _channel,
  );
  final watches = [
    for (var v = 0; v < 90; v++) ...[
      watch(v, start.add(Duration(days: v * 23))),
      if (v % 7 == 0 && v < 84)
        for (var again = 1; again <= 1 + (v ~/ 7) % 5; again++)
          watch(v, start.add(Duration(days: v * 23 + again * 3))),
    ],
  ]..sort((a, b) => b.time.compareTo(a.time));
  return TakeoutHistory(watches: watches);
}
