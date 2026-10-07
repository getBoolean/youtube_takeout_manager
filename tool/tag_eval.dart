// Tag eval: runs the real Jev and Claude steps on a few example channels of
// the takeout open in the app, and prints the tags each gets beside the ones
// expected, with what Claude cost. It reads the takeout, the keys, the tags
// and the cached channel topics and video descriptions, and saves nothing:
// the tags Claude names are kept in memory only, for the channels after.
// Signed out, so it fetches nothing from YouTube. It costs a few cents of
// the keys' credit.
//
// flutter run -d windows -t tool/tag_eval.dart --dart-define-from-file=.env
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/category_pipeline.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/jev_prompts.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/categorization_plan.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/name_key.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/run_estimate.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_candidates.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_topics.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

/// The channels to try, by name, in this order, with the tags each should
/// get.
const _examples = <String, List<String>>{
  'Usami Mizuki 2.0': ['Anime Clips'],
  'Karting All Day': ['Mario Kart World'],
  'Ayunda Risu Ch. hololive-ID': ['VTuber', 'Hololive'],
  'Ichinagi Ch.': ['VTuber Clips'],
  'rachie': ['Cover Artist'],
  'Squirreltail Animation': ['MMD', 'Loli/Lolicon'],
  'Glass Reflection': ['Anime', 'Anime Essays'],
  'Albert Boris': ['Nintendo'],
  'Keralis': ['Minecraft', 'Hermitcraft'],
  'kyOresu': ['Cover Artist', 'VTuber', 'Loli/Lolicon'],
  'Miwa Ch. みわ': ['Cover Artist', 'VTuber', 'ASMR', 'Roleplay', 'Loli/Lolicon'],
  'Artimisblue': ['Beatsaber'],
  'Hydreix': ['Mario Kart 8 Deluxe'],
  'Jelly Ch. 【Phase Connect】': ['VTuber', 'Phase Connect', 'Music', 'Gaming'],
  'Pomf Pomf': ['Music', 'Loli/Lolicon'],
};

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(
    overrides: [
      // Signed out: nothing is fetched, so no quota is spent.
      readSessionChannelIdProvider.overrideWith((ref) => null),
    ],
  );
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Tag eval: see the console.'))),
    ),
  );
  unawaited(
    _eval(
      container,
    ).catchError((Object e) => _log('Stopped: $e')).whenComplete(() => exit(0)),
  );
}

Future<void> _eval(ProviderContainer container) async {
  container
    ..listen(takeoutProvider, (_, _) {})
    ..listen(videoMetadataProvider, (_, _) {});
  if (await container.read(takeoutProvider.future) == null) {
    return _log('No takeout is open; open one in the app first.');
  }
  final loaded = await container.read(takeoutHistoryProvider.future);
  if (loaded == null) return _log('The takeout has no watch history.');
  final keys = await container.read(aiKeysProvider.future);
  if (!keys.hasAny) return _log('Add a Jev or Claude key in the app first.');

  final details = await container.read(channelDetailsProvider.future);
  final videos = await container.read(videoMetadataProvider.future);
  final categories = await container.read(channelCategoriesProvider.future);
  // A copy: the tags Claude names are kept here, never saved.
  final names = {...await container.read(tagNamesProvider.future)};
  await container.read(customCategoriesProvider.future);
  final taxonomy = container.read(categoryTaxonomyProvider);

  var input = 0;
  var output = 0;
  final jev = keys.hasJev
      ? (
          repository: container.read(typeSafeRepositoryProvider),
          apiKey: keys.keyFor(AiService.jev),
        )
      : null;
  final claudeRepository = container.read(anthropicRepositoryProvider);
  final claude = keys.hasClaude
      ? (
          repository: claudeRepository,
          apiKey: keys.keyFor(AiService.claude),
          model: await claudeRepository.capabilities(
            apiKey: keys.keyFor(AiService.claude),
            model: anthropicModel,
          ),
        )
      : null;
  final pipeline = CategoryPipeline(
    taxonomy: taxonomy,
    jev: jev,
    claude: claude,
    onUsage: (i, o) {
      input += i;
      output += o;
    },
  );
  final picks = pickPromptVideos(loaded);
  final watches = loaded.history.watches;
  _log(
    'Tag eval: ${_examples.length} channels, with '
    '${[if (keys.hasJev) 'Jev', if (keys.hasClaude) 'Claude ($anthropicModel)'].join(' and ')}; '
    '${names.length} tags kept to start from.',
  );

  var matched = 0;
  var expected = 0;
  for (final MapEntry(key: title, value: wanted) in _examples.entries) {
    final channel = _find(loaded.watchedChannels, title);
    expected += wanted.length;
    if (channel == null) {
      _log('\n$title: not in this takeout\'s watch history');
      continue;
    }
    final channelDetails = details[channel.channelId];
    final topicUrls = channelDetails?.topicUrls ?? const <String>[];
    final index = loaded.channelIndexByKey[channel.key];
    final PromptPicks channelPicks = index == null
        ? (titles: const [], described: const [])
        : picks[index];
    final evidence = buildEvidence(
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
    );
    final tags = TagIndex.of(names, categories);

    // What Jev makes of the tags there are, before the full run.
    var jevSays = '(no Jev key)';
    if (jev != null) {
      final candidates = tags.candidatesFor(
        evidence,
        categories[channel.key]?.path ??
            youtubeCandidates(topicUrls).firstOrNull,
      );
      if (candidates.isEmpty) {
        jevSays = 'no tags to offer it';
      } else {
        final read = readJevTags(
          await jev.repository.ask(
            apiKey: jev.apiKey,
            state: evidence.toState(),
            questions: jevTagQuestions(candidates),
          ),
          candidates,
        );
        final kept = [
          for (final candidate in candidates)
            if ((read.yes[candidate.key] ?? 0) >= jevThreshold)
              '${candidate.tag.name} (${read.yes[candidate.key]!.toStringAsFixed(2)})',
        ];
        jevSays =
            '${kept.isEmpty ? 'none of ${candidates.length} fit' : kept.join(', ')}; '
            'other ${read.other.toStringAsFixed(2)}';
      }
    }

    final result = await pipeline.categorize((
      key: channel.key,
      evidence: evidence,
      topicUrls: topicUrls,
    ), tags: tags);
    final named = pipeline.takeNamedTags();
    for (final (:name, :meaning) in named) {
      final key = nameKey(name);
      names.putIfAbsent(key, () => TagName(name: name, meaning: meaning));
    }
    final got = {for (final tag in result.tags) nameKey(tag)};
    final hits = [
      for (final tag in wanted)
        if (got.contains(nameKey(tag))) tag,
    ];
    matched += hits.length;
    _log(
      '\n${channel.title}: ${result.path?.label ?? 'no category'}\n'
      '  Jev: $jevSays\n'
      '  Claude added: ${named.isEmpty ? 'nothing' : [for (final (:name, :meaning) in named) '$name ($meaning)'].join('; ')}\n'
      '  got:      ${result.tags.join(', ')}\n'
      '  expected: ${wanted.join(', ')}  (${hits.length} of ${wanted.length})',
    );
  }
  final spent = claude == null || anthropicModel != defaultAnthropicModel
      ? ''
      : ', about \$${claudeDollars(input, output).toStringAsFixed(3)}';
  _log(
    '\n$matched of $expected expected tags found. Claude: $input tokens in, '
    '$output out$spent.',
  );
}

/// The channel named [title], whatever its case or accents, else one whose
/// name holds it.
HistoryChannel? _find(List<WatchedChannel> channels, String title) {
  final wanted = foldForSearch(title.trim());
  for (final watched in channels) {
    if (foldForSearch(watched.channel.title.trim()) == wanted) {
      return watched.channel;
    }
  }
  for (final watched in channels) {
    if (foldForSearch(watched.channel.title).contains(wanted)) {
      return watched.channel;
    }
  }
  return null;
}

void _log(String line) {
  // ignore: avoid_print
  print(line);
}
