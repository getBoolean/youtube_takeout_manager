import 'dart:convert';

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
/// new one, with its emoji), the channel's tags, and why.
typedef ClaudeSuggestion = ({
  String parent,
  String? child,
  String? emoji,
  List<String> tags,
  String reason,
});

/// What Claude is told about naming tags, reusing [knownTags].
String _tagInstructions(List<String> knownTags) => [
  'name up to 5 tags for what the channel is specifically about: a game, a '
      'series, a person, a genre or a theme, like Mario Kart World, Blue '
      'Archive, Anime, ASMR or NSFW.',
  if (knownTags.isNotEmpty)
    'Reuse one of these tags only when it names the same thing: '
        '${knownTags.join(', ')}. Otherwise name a new one, short, in the '
        'same style.'
  else
    'Keep each one short.',
  'Give fewer tags, or none, when nothing more specific fits.',
].join(' ');

const _tagsSchema = {
  'type': 'array',
  'items': {'type': 'string'},
};

/// Asks Claude to categorize a channel from [evidence]: a category of
/// [taxonomy], and one of its sub-categories, reusing one that fits before
/// naming a new one, with an emoji; and the channel's tags, reusing
/// [knownTags]. With [inaccurate], it's told the category the channel had
/// is wrong.
ClaudeRequest claudeCategoryRequest(
  ChannelEvidence evidence,
  Taxonomy taxonomy, {
  List<String> knownTags = const [],
  CategoryPath? inaccurate,
}) {
  final categories = [
    for (final parent in taxonomy.parents)
      taxonomy.childrenOf(parent).isEmpty
          ? '- $parent'
          : '- $parent: ${taxonomy.childrenOf(parent).join(', ')}',
  ].join('\n');
  final system =
      'You categorize YouTube channels by the videos they make and the '
      'ones a viewer watched from them.\n\n'
      'Categories, each with its sub-categories:\n$categories\n\n'
      'Pick the category that fits best. Then, within it, reuse the '
      'sub-category that fits if there is one. Only if none does, name a '
      'new sub-category of one to three words, in the style of the others, '
      'with one emoji for it. Use no sub-category when the channel spans '
      'the whole category. Give the reason in 20 words or fewer.\n\n'
      'Then ${_tagInstructions(knownTags)}';
  final user = jsonEncode({
    ...evidence.toState(),
    if (inaccurate != null)
      'note':
          'The viewer says "${inaccurate.label}" is wrong for this channel. '
          'Pick something else.',
  });
  return (
    system: system,
    user: user,
    schema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['parent', 'child', 'emoji', 'tags', 'reason'],
      'properties': {
        'parent': {'type': 'string', 'enum': taxonomy.parents.toList()},
        'child': {
          'anyOf': [
            {'type': 'string'},
            {'type': 'null'},
          ],
        },
        'emoji': {
          'anyOf': [
            {'type': 'string'},
            {'type': 'null'},
          ],
        },
        'tags': _tagsSchema,
        'reason': {'type': 'string'},
      },
    },
  );
}

/// Asks Claude for the tags alone of a channel already in [category], from
/// [evidence], reusing [knownTags].
ClaudeRequest claudeTagsRequest(
  ChannelEvidence evidence,
  CategoryPath category, {
  List<String> knownTags = const [],
}) {
  final instructions = _tagInstructions(knownTags);
  return (
    system:
        'You tag YouTube channels by what they are specifically about, from '
        'the videos they make and the ones a viewer watched from them. Given '
        'the channel and its category, '
        '$instructions',
    user: jsonEncode({...evidence.toState(), 'category': category.label}),
    schema: {
      'type': 'object',
      'additionalProperties': false,
      'required': ['tags'],
      'properties': {'tags': _tagsSchema},
    },
  );
}

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
    tags: parseClaudeTags(answer['tags']),
    reason: reason is String ? reason.trim() : '',
  );
}

/// The tags in Claude's answer [tags]: text only, tidied, each once by
/// [nameKey], at most [maxTags].
List<String> parseClaudeTags(Object? tags) {
  if (tags is! List) return const [];
  final kept = <String>[];
  final keys = <String>{};
  for (final tag in tags) {
    if (kept.length == maxTags) break;
    if (tag is! String) continue;
    final tidy = tidyTagName(tag);
    if (tidy != null && keys.add(nameKey(tidy))) kept.add(tidy);
  }
  return kept;
}

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
