import 'dart:convert';

import 'category_path.dart';
import 'channel_evidence.dart';
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
/// new one), and why.
typedef ClaudeSuggestion = ({String parent, String? child, String reason});

/// Asks Claude to categorize a channel from [evidence]: a category of
/// [taxonomy], and one of its sub-categories, reusing one that fits before
/// naming a new one. With [inaccurate], it's told the category the channel
/// had is wrong.
ClaudeRequest claudeCategoryRequest(
  ChannelEvidence evidence,
  Taxonomy taxonomy, {
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
      'new sub-category of one to three words, in the style of the others. '
      'Use no sub-category when the channel spans the whole category. '
      'Give the reason in 20 words or fewer.';
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
      'required': ['parent', 'child', 'reason'],
      'properties': {
        'parent': {'type': 'string', 'enum': taxonomy.parents.toList()},
        'child': {
          'anyOf': [
            {'type': 'string'},
            {'type': 'null'},
          ],
        },
        'reason': {'type': 'string'},
      },
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
  return (
    parent: parent,
    child: normalizeChildName(answer['child'] as String?),
    reason: reason is String ? reason.trim() : '',
  );
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
