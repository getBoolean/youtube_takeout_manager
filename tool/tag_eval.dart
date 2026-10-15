// Tag eval: runs the real Jev and Claude steps on a few example channels of
// the takeout open in the app, as a run's waves would, and prints the tags
// each gets beside the ones expected, with what Claude cost. Pass 1 starts
// from the tags there are; pass 2 asks for the same channels' tags again,
// with the tags pass 1 named, as a run's later waves reuse the tags earlier
// ones named. Claude is asked about the channels in groups, as a run asks.
// It reads the takeout, the keys, the tags and the cached channel topics and
// video descriptions, and saves nothing: the tags Claude names are kept in
// memory only. Signed out, so it fetches nothing from YouTube. It costs a
// few cents of the keys' credit.
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
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/categorization_plan.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/name_key.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/run_estimate.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_candidates.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

/// The channels to try, by name or channel ID (`UC…`), in this order, with
/// the tags each should get.
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

/// A pass's first wave: each channel categorized, with its tags.
const _categorizing = (
  work: ChannelWork.categorize,
  redo: false,
  checkTags: false,
);

/// A later wave: each channel's tags asked for again, its category kept.
const _retagging = (work: ChannelWork.tags, redo: true, checkTags: false);

/// An example found in the takeout: the channel, its tags expected, and
/// what's known about it.
typedef _Example = ({
  HistoryChannel channel,
  List<String> wanted,
  ChannelInput input,
});

/// What Jev said about a channel's tags: how many it was offered, how sure
/// it is of each, by key, and that the channel is about something none of
/// them name.
typedef JevSaid = ({int offered, Map<String, double> yes, double other});

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
  var names = {...await container.read(tagNamesProvider.future)};
  await container.read(customCategoriesProvider.future);
  final taxonomy = container.read(categoryTaxonomyProvider);
  final subscriptions = await container.read(
    historySubscriptionsProvider.future,
  );
  final channels = [
    for (final watched in loaded.watchedChannels) watched.channel,
    ...matchSubscriptions(
      loaded.watchedChannels,
      subscriptions.values,
    ).unwatched,
  ];

  var inputTokens = 0;
  var outputTokens = 0;
  final jevSaid = <String, JevSaid>{};
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
      inputTokens += i;
      outputTokens += o;
    },
    onJevTags: (key, offered, yes, other) =>
        jevSaid[key] = (offered: offered, yes: yes, other: other),
  );
  _log(
    'Tag eval: ${_examples.length} channels, with '
    '${[if (keys.hasJev) 'Jev', if (keys.hasClaude) 'Claude ($anthropicModel)'].join(' and ')}; '
    '${names.length} tags kept to start from.',
  );

  final picks = loaded.promptPicks;
  final examples = <_Example>[];
  var expected = 0;
  for (final MapEntry(key: example, value: wanted) in _examples.entries) {
    expected += wanted.length;
    final channel = _find(channels, example);
    if (channel == null) {
      final near = nearChannelNames(channels, example);
      _log(
        '\n$example: not in this takeout\'s watch history or subscriptions'
        '${near.isEmpty ? '' : '; near: ${near.join(', ')}'}',
      );
      continue;
    }
    examples.add((
      channel: channel,
      wanted: wanted,
      input: channelInputFor(channel, loaded, details, picks, videos),
    ));
  }
  if (examples.isEmpty) return;

  /// One pass over the examples as [plan] has it, each channel's results
  /// from the pass [before] to go on from: Jev for each, then Claude for
  /// those left for it, in groups. Prints what each got, and the pass's
  /// totals.
  Future<Map<String, ChannelCategory>> pass(
    String heading,
    WorkPlan plan,
    Map<String, ChannelCategory> before,
  ) async {
    inputTokens = 0;
    outputTokens = 0;
    jevSaid.clear();
    final known = {...names};
    final index = TagIndex.of(names, {...categories, ...before});
    final results = <String, ChannelCategory>{};
    final asked = <String, ClaudeAsk>{};
    final tickets = <ClaudeTicket>[];
    for (final (:channel, wanted: _, :input) in examples) {
      // Retagging needs the category the pass before gave it.
      if (plan.work == ChannelWork.tags && !before.containsKey(channel.key)) {
        continue;
      }
      switch (await pipeline.prepare(
        input,
        plan,
        existing: before[channel.key],
        tags: index,
      )) {
        case Settled(:final result):
          results[channel.key] = result;
        case NeedsClaude(:final ticket):
          asked[channel.key] = ticket.ask;
          tickets.add(ticket);
        case Checked():
      }
    }
    await pipeline.askClaude(
      tickets,
      stopped: () => false,
      tags: index,
      onResult: (key, result) => results[key] = result,
    );
    // As a run keeps them: each channel's tags spelled as the tags there
    // are, a new one with the meaning Claude gave it.
    final meanings = {
      for (final (:name, :meaning) in pipeline.takeNamedTags())
        nameKey(name): ?meaning,
    };
    pipeline.takeLearned();

    _log('\n=== $heading ===');
    var matched = 0;
    for (final (:channel, :wanted, input: _) in examples) {
      final result = results[channel.key];
      if (result == null) {
        _log('\n${channel.title}: no answer');
        continue;
      }
      final merged = mergeNamedTags(names, [
        for (final tag in result.tags)
          (name: tag, meaning: meanings[nameKey(tag)]),
      ], NameOrigin.ai);
      names = {...merged.names};
      final tagged = result.copyWith(tags: merged.resolved);
      results[channel.key] = tagged;

      final report = channelReport(
        tagged,
        withJev: jev != null,
        said: jevSaid[channel.key],
        asked: asked[channel.key],
        names: names,
        known: known.keys.toSet(),
        wanted: wanted,
      );
      matched += report.hits.length;
      _log(
        '\n${channel.title}: ${report.category}\n'
        '  Jev: ${report.jev}\n'
        '  Claude: ${report.claude}\n'
        '  got:${report.tags.isEmpty ? ' nothing' : [for (final tag in report.tags) '\n    - $tag'].join()}\n'
        '  expected: ${wanted.join(', ')}  (${report.hits.length} of '
        '${wanted.length})',
      );
    }
    final spent = claude == null || anthropicModel != defaultAnthropicModel
        ? ''
        : ', about \$${claudeDollars(inputTokens, outputTokens).toStringAsFixed(3)}';
    final reach = claudeReach(asked, before: before);
    // Going on from a pass before, each channel keeps its category and is
    // offered the tags named for it: the least a later wave asks of Claude.
    final bestCase = before.isEmpty
        ? ''
        : '\nThis is the least a later wave asks of Claude: each channel kept '
              'its category and was offered the tags named for it. A later '
              'wave would also ask Claude to categorize channels like the '
              '${reach.categorizedByClaudeBefore} only Claude could '
              'categorize in the pass before.';
    _log(
      '\n$heading: $matched of $expected expected tags found. Claude was '
      'asked about ${asked.length} of ${examples.length} channels '
      '(${reach.categories} for a category and its tags, ${reach.tags} for '
      'tags alone): $inputTokens tokens in, $outputTokens out$spent.'
      '$bestCase',
    );
    return results;
  }

  final first = await pass(
    'Pass 1, from the tags there are',
    _categorizing,
    const {},
  );
  await pass('Pass 2, with the tags pass 1 named', _retagging, first);
}

/// What a pass made of a channel, to print: its category; what Jev said of
/// its tags; what Claude was asked for; each tag it got, with who gave it,
/// whether it's new, and its meaning; and the tags expected that it got.
typedef ChannelReport = ({
  String category,
  String jev,
  String claude,
  List<String> tags,
  List<String> hits,
});

/// The report of a channel's [result] in a pass: Jev [said] what it did of
/// its tags, [withJev] being whether there's a Jev key to ask with, and
/// Claude was [asked] for what, if anything. Each tag shows its meaning as
/// [names] have it, and is new when it isn't among the keys [known];
/// [wanted] are the tags expected.
ChannelReport channelReport(
  ChannelCategory result, {
  required bool withJev,
  required JevSaid? said,
  required ClaudeAsk? asked,
  required Map<String, TagName> names,
  required Set<String> known,
  required List<String> wanted,
}) {
  final kept = {
    for (final MapEntry(:key, value: yes)
        in said?.yes.entries ?? const <MapEntry<String, double>>[])
      if (yes >= jevThreshold) key: yes,
  };
  final got = {for (final tag in result.tags) nameKey(tag)};
  return (
    category: result.path?.label ?? 'no category',
    jev: switch ((said, asked)) {
      _ when !withJev => 'no Jev key',
      (null, _) when result.path == null =>
        'not asked: no category to tag it within',
      (null, ClaudeAsk.category) => 'not asked: Claude named the category',
      (null, _) => 'no tags to offer it',
      (final said?, _) =>
        '${kept.isEmpty ? 'none of ${said.offered} fit' : [for (final MapEntry(:key, value: yes) in kept.entries) '${names[key]?.name ?? key} (${yes.toStringAsFixed(2)})'].join(', ')}; '
            'other ${said.other.toStringAsFixed(2)}',
    },
    claude: switch (asked) {
      ClaudeAsk.category => 'asked for the category and tags',
      ClaudeAsk.tags => 'asked for tags',
      null => 'not asked',
    },
    tags: [
      for (final tag in result.tags)
        '$tag (${[kept.containsKey(nameKey(tag)) ? 'Jev' : 'Claude', if (!known.contains(nameKey(tag))) 'new'].join(', ')}): '
            '${names[nameKey(tag)]?.meaning ?? 'no meaning'}',
    ],
    hits: [
      for (final tag in wanted)
        if (got.contains(nameKey(tag))) tag,
    ],
  );
}

/// The channel [example] names among [channels]: by its channel ID when
/// it's one; else by its name, whatever its case or accents, else one whose
/// name holds it.
HistoryChannel? _find(List<HistoryChannel> channels, String example) {
  final wanted = example.trim();
  for (final channel in channels) {
    if (channel.channelId == wanted) return channel;
  }
  final folded = foldForSearch(wanted);
  for (final channel in channels) {
    if (foldForSearch(channel.title.trim()) == folded) return channel;
  }
  for (final channel in channels) {
    if (foldForSearch(channel.title).contains(folded)) return channel;
  }
  return null;
}

/// Up to 3 of [channels] named most like [example], the likest first,
/// whatever the case, accents or spaces: where to look when it isn't
/// found. Names are alike by the pairs of letters they share, so a name
/// spelled a little differently is still found.
List<String> nearChannelNames(List<HistoryChannel> channels, String example) {
  final wanted = _letterPairs(example);
  if (wanted.isEmpty) return const [];
  final alike = <(double, String)>[];
  for (final channel in channels) {
    final pairs = _letterPairs(channel.title);
    if (pairs.isEmpty) continue;
    final shared = pairs.where(wanted.contains).length;
    final likeness = 2 * shared / (pairs.length + wanted.length);
    if (likeness >= 0.5) alike.add((likeness, channel.title));
  }
  alike.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final (_, title) in alike.take(3)) title];
}

/// The pairs of letters next to each other in [name], folded, its spaces
/// left out.
Set<String> _letterPairs(String name) {
  final folded = foldForSearch(name).replaceAll(RegExp(r'\s+'), '');
  return {
    for (var i = 0; i + 1 < folded.length; i++) folded.substring(i, i + 2),
  };
}

/// How many channels a pass asked Claude about, [asked], by what for: a
/// category with its tags, or tags alone; and how many of the channels it
/// went on from, [before], only Claude could categorize.
({int categories, int tags, int categorizedByClaudeBefore}) claudeReach(
  Map<String, ClaudeAsk> asked, {
  Map<String, ChannelCategory> before = const {},
}) => (
  categories: asked.values.where((ask) => ask == ClaudeAsk.category).length,
  tags: asked.values.where((ask) => ask == ClaudeAsk.tags).length,
  categorizedByClaudeBefore: before.values
      .where((category) => category.source == CategorySource.claude)
      .length,
);

void _log(String line) {
  // ignore: avoid_print
  print(line);
}
