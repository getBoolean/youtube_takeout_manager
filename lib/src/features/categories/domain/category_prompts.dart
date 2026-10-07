import 'dart:convert';
import 'dart:math';

import 'category_path.dart';
import 'channel_category.dart';
import 'channel_evidence.dart';
import 'name_key.dart';
import 'tag_name.dart';
import 'youtube_taxonomy.dart';

/// The longest a sub-category AI names can be.
const maxChildName = 40;

/// What Claude is asked: how, about what, and the JSON its answer takes.
typedef ClaudeRequest = ({
  String system,
  String user,
  Map<String, Object?> schema,
});

/// What Claude answered: a category, a sub-category within it (possibly a
/// new one, with its emoji), the channel's tags (a new one with its
/// meaning), and why.
typedef ClaudeSuggestion = ({
  String parent,
  String? child,
  String? emoji,
  List<NamedTag> tags,
  String reason,
});

/// The most channels one request to Claude asks about.
const maxGroupChannels = 20;

/// Bumped when how channels are framed in a request to Claude changes in a
/// way that could change its answers: every Claude fingerprint changes
/// with it. How many channels a request holds changes none.
const claudeFramingVersion = 1;

/// Part of what Claude is asked about a channel: what it's told, and the
/// properties of its answer.
typedef ClaudePart = ({String instructions, Map<String, Object?> properties});

/// The most characters of channels' evidence one request to Claude holds.
const maxGroupEvidence = 40000;

/// A channel in a request to Claude: its [id] there (`c1`…), what's known
/// about it, the [category] it has when only its tags are asked for, the
/// tags already found for it ([keptTags]), to add to, and a category the
/// user says is wrong ([inaccurate]).
typedef ClaudeItem = ({
  String id,
  ChannelEvidence evidence,
  CategoryPath? category,
  List<String> keptTags,
  CategoryPath? inaccurate,
});

/// Claude's [answer], or null when it names a category [taxonomy] lacks.
/// The sub-category is tidied, not looked up: it may be a new one.
ClaudeSuggestion? parseClaudeSuggestion(
  Map<String, Object?> answer,
  Taxonomy taxonomy,
) {
  final parent = taxonomy.find('${answer['parent'] ?? ''}')?.parent;
  if (parent == null) return null;
  final reason = answer['reason'];
  final child = answer['child'];
  return (
    parent: parent,
    child: normalizeChildName(child is String ? child : null),
    emoji: parseEmoji(answer['emoji']),
    tags: parseNamedTags(answer['tags']),
    reason: reason is String ? reason.trim() : '',
  );
}

/// What Claude is told about the kinds of tags, the tags there are to
/// reuse, [knownTags] (the user's with their meanings), and adding to the
/// tags found.
String _groupTagInstructions(List<NamedTag> knownTags, {required bool found}) {
  final explained = [
    for (final (:name, :meaning) in knownTags)
      if (meaning != null) '- $name: $meaning',
  ];
  final named = [
    for (final (:name, :meaning) in knownTags)
      if (meaning == null) name,
  ];
  return [
    "Name each channel's tags: what it is specifically about, as a viewer "
        'would tag it. A tag can say:',
    '- what the creator is, like VTuber or Cover Artist;',
    '- what it makes, like Anime Clips, Anime Essays or MMD;',
    '- what it is about: a game by its exact title (Mario Kart World and '
        'Mario Kart 8 Deluxe are different tags), a franchise or company '
        'like Nintendo or Minecraft, or a broad subject like Music or Gaming '
        'when the channel spans more than its category;',
    '- who it is with, like Hololive, Phase Connect or Hermitcraft;',
    '- a theme, like ASMR or Roleplay.',
    if (explained.isNotEmpty || named.isNotEmpty) ...[
      'Reuse one of these tags when it names the same thing, spelled as '
          'here, with an empty meaning:',
      ...explained,
      if (named.isNotEmpty) named.join(', '),
      'Otherwise name a new tag, short, in the same style, with its meaning '
          'in 15 words or fewer.',
    ] else
      'Keep each tag short, with its meaning in 15 words or fewer.',
    if (found)
      "A channel's tags_found are tags it already has: add only what they "
          'miss.',
    'Give at most 5 tags in all, counting tags_found; fewer, or none, when '
        'nothing more specific fits.',
  ].join('\n');
}

/// The JSON Claude answers in: one answer per channel, by an [ids] one,
/// with [properties] besides.
Map<String, Object?> _groupSchema(
  List<String> ids,
  Map<String, Object?> properties,
) {
  final item = {
    'id': {'type': 'string', 'enum': ids},
    ...properties,
  };
  return {
    'type': 'object',
    'additionalProperties': false,
    'required': ['answers'],
    'properties': {
      'answers': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': item.keys.toList(),
          'properties': item,
        },
      },
    },
  };
}

const _namedTagsSchema = {
  'type': 'array',
  'items': {
    'type': 'object',
    'additionalProperties': false,
    'required': ['name', 'meaning'],
    'properties': {
      'name': {'type': 'string'},
      'meaning': {'type': 'string'},
    },
  },
};

/// [items] as Claude is told them: each channel's evidence with its id,
/// and its category, the tags found for it and a note when there are.
String _groupUser(List<ClaudeItem> items, {required bool withCategory}) =>
    jsonEncode({
      'channels': [
        for (final item in items)
          {
            'id': item.id,
            ...item.evidence.toState(),
            if (withCategory && item.category != null)
              'category': item.category!.label,
            if (item.keptTags.isNotEmpty) 'tags_found': item.keptTags,
            if (item.inaccurate case final wrong?)
              'note':
                  'The viewer says "${wrong.label}" is wrong for this '
                  'channel. Pick something else.',
          },
      ],
    });

/// What Claude is told and answers about a channel's category: each of
/// [taxonomy]'s categories with its sub-categories, reusing one that fits
/// before naming a new one, with an emoji, and why.
ClaudePart claudeCategoryPart(Taxonomy taxonomy) {
  final categories = [
    for (final parent in taxonomy.parents)
      taxonomy.childrenOf(parent).isEmpty
          ? '- $parent'
          : '- $parent: ${taxonomy.childrenOf(parent).join(', ')}',
  ].join('\n');
  return (
    instructions:
        'Categories, each with its sub-categories:\n$categories\n\n'
        'For each channel, pick the category that fits best. Then, within '
        'it, reuse the sub-category that fits if there is one. Only if none '
        'does, name a new sub-category of one to three words, in the style '
        'of the others, with one emoji for it; otherwise leave the emoji '
        'empty. Leave the sub-category empty when the channel spans the '
        'whole category. Give the reason in 20 words or fewer.',
    properties: {
      'parent': {'type': 'string', 'enum': taxonomy.parents.toList()},
      'child': {'type': 'string'},
      'emoji': {'type': 'string'},
      'reason': {'type': 'string'},
    },
  );
}

/// What Claude is told and answers about a channel's tags: the kinds of
/// tags, reusing [knownTags] (the user's with their meanings), and, when
/// tags were [found] for some channel, adding only what they miss.
ClaudePart claudeTagsPart(List<NamedTag> knownTags, {required bool found}) => (
  instructions: _groupTagInstructions(knownTags, found: found),
  properties: {'tags': _namedTagsSchema},
);

/// How a request to Claude about several channels opens, saying what it
/// is to do with them, [doing].
String _framing(String doing) =>
    'You $doing YouTube channels by the videos they make and the ones a '
    'viewer watched from them. Each channel comes with an id: answer for '
    'every channel, once, by its id.';

/// Asks Claude to categorize the channels [items]: for each, a category
/// of [taxonomy] and one of its sub-categories, reusing one that fits
/// before naming a new one, with an emoji; and its tags, reusing
/// [knownTags].
ClaudeRequest claudeCategoryGroupRequest(
  List<ClaudeItem> items,
  Taxonomy taxonomy, {
  List<NamedTag> knownTags = const [],
}) {
  final category = claudeCategoryPart(taxonomy);
  final tags = claudeTagsPart(
    knownTags,
    found: items.any((item) => item.keptTags.isNotEmpty),
  );
  return (
    system:
        '${_framing('categorize')}\n\n${category.instructions}\n\n'
        '${tags.instructions}',
    user: _groupUser(items, withCategory: false),
    schema: _groupSchema(
      [for (final item in items) item.id],
      {...category.properties, ...tags.properties},
    ),
  );
}

/// Asks Claude for the tags alone of the channels [items], each in its
/// category, adding to the tags found for it, reusing [knownTags].
ClaudeRequest claudeTagsGroupRequest(
  List<ClaudeItem> items, {
  List<NamedTag> knownTags = const [],
}) {
  final tags = claudeTagsPart(
    knownTags,
    found: items.any((item) => item.keptTags.isNotEmpty),
  );
  return (
    system:
        '${_framing('tag')} Each also comes with its category.\n\n'
        '${tags.instructions}',
    user: _groupUser(items, withCategory: true),
    schema: _groupSchema([for (final item in items) item.id], tags.properties),
  );
}

/// The answers in Claude's [answer] to a group, by id: for each of [ids],
/// its first answer; ids not asked about are left out, as are answers
/// naming a category [taxonomy] lacks.
Map<String, ClaudeSuggestion> parseClaudeGroup(
  Map<String, Object?> answer,
  Set<String> ids,
  Taxonomy taxonomy,
) {
  final parsed = <String, ClaudeSuggestion>{};
  for (final item in _answers(answer, ids)) {
    final id = item['id']! as String;
    if (parsed.containsKey(id)) continue;
    if (parseClaudeSuggestion(item, taxonomy) case final suggestion?) {
      parsed[id] = suggestion;
    }
  }
  return parsed;
}

/// The tags in Claude's [answer] to a group asking for tags alone, by id:
/// for each of [ids], its first answer's, at most the [room] it has.
Map<String, List<NamedTag>> parseClaudeTagsGroup(
  Map<String, Object?> answer,
  Set<String> ids,
  Map<String, int> room,
) {
  final parsed = <String, List<NamedTag>>{};
  for (final item in _answers(answer, ids)) {
    final id = item['id']! as String;
    parsed.putIfAbsent(
      id,
      () => parseNamedTags(item['tags'], room: room[id] ?? maxTags),
    );
  }
  return parsed;
}

/// The answers in [answer] whose id is one of [ids].
Iterable<Map<String, Object?>> _answers(
  Map<String, Object?> answer,
  Set<String> ids,
) sync* {
  final answers = answer['answers'];
  if (answers is! List) return;
  for (final item in answers) {
    if (item case {'id': final String id} when ids.contains(id)) {
      yield item.cast<String, Object?>();
    }
  }
}

/// The tags in Claude's answer [tags], with their meanings: text only,
/// tidied, each once by [nameKey], at most [room]; an empty meaning is
/// none.
List<NamedTag> parseNamedTags(Object? tags, {int room = maxTags}) {
  if (tags is! List) return const [];
  final kept = <NamedTag>[];
  final keys = <String>{};
  for (final tag in tags) {
    if (kept.length >= room) break;
    final (name, meaning) = switch (tag) {
      {'name': final String name, 'meaning': final Object? meaning} => (
        name,
        meaning is String ? meaning : null,
      ),
      final String name => (name, null),
      _ => (null, null),
    };
    if (name == null) continue;
    final tidy = tidyTagName(name);
    if (tidy != null && keys.add(nameKey(tidy))) {
      kept.add((name: tidy, meaning: tidyTagMeaning(meaning)));
    }
  }
  return kept;
}

/// [items] in requests to Claude, in order: at most [maxChannels] each, and
/// at most [maxChars] of their [chars], but one larger alone.
List<List<T>> packGroups<T>(
  List<T> items,
  int Function(T item) chars, {
  int maxChannels = maxGroupChannels,
  int maxChars = maxGroupEvidence,
}) {
  final groups = <List<T>>[];
  var group = <T>[];
  var size = 0;
  for (final item in items) {
    final itemChars = chars(item);
    if (group.isNotEmpty &&
        (group.length >= maxChannels || size + itemChars > maxChars)) {
      groups.add(group);
      group = <T>[];
      size = 0;
    }
    group.add(item);
    size += itemChars;
  }
  if (group.isNotEmpty) groups.add(group);
  return groups;
}

/// How long Claude's answer about [channels] channels may be: room for
/// each one's category and tags ([withCategory]) or tags alone, up to the
/// model's [modelMax].
int groupAnswerTokens(
  int channels, {
  required bool withCategory,
  int? modelMax,
}) => min(modelMax ?? 16384, 200 + channels * (withCategory ? 220 : 150));

final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// The emoji in Claude's answer [emoji]: a short one with no letters or
/// digits, else none.
String? parseEmoji(Object? emoji) {
  if (emoji is! String) return null;
  final trimmed = emoji.trim();
  if (trimmed.isEmpty || trimmed.length > 16) return null;
  return _letterOrDigit.hasMatch(trimmed) ? null : trimmed;
}

/// [name] trimmed, with single spaces, at most [maxChildName] long; null
/// when blank.
String? normalizeChildName(String? name) {
  final tidy = (name ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (tidy.isEmpty) return null;
  return tidy.length <= maxChildName
      ? tidy
      : tidy.substring(0, maxChildName).trimRight();
}
