import '../data/typesafe_repository.dart';
import '../domain/category_path.dart';
import '../domain/tag_candidates.dart';
import '../domain/youtube_taxonomy.dart';

/// The option for "none of these".
const jevGeneral = '_none';

/// [names] as Jev's options, by key. Jev reads keys, so they say what they
/// are, in ASCII; a name with no Latin letters or digits is `option`, and
/// keys that would be the same get `_2`, `_3`… Never [jevGeneral].
Map<String, String> jevOptionKeys(Iterable<String> names) {
  final options = <String, String>{};
  for (final name in names) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = slug.isEmpty ? 'option' : slug;
    var key = base;
    for (var n = 2; options.containsKey(key) || key == jevGeneral; n++) {
      key = '${base}_$n';
    }
    options[key] = name;
  }
  return options;
}

/// Whether YouTube's category [candidate] fits the channel.
JevNoul jevFitQuestion(CategoryPath candidate) => JevNoul(
  'Does the category "${candidate.label}" describe the videos this channel '
  'makes and the ones the user watched from it?',
  whenTrue: 'It clearly describes most of them.',
  whenFalse: 'It does not, or only a small part of them.',
);

/// Which of [taxonomy]'s categories fits the channel, each described by its
/// sub-categories, by the keys [jevOptionKeys] gives them. A category with
/// no sub-categories to pick instead is left out when [exclude] rules it
/// out.
JevChoice jevParentQuestion(Taxonomy taxonomy, {CategoryPath? exclude}) =>
    JevChoice(
      'Which category best describes the videos this channel makes and the '
      'ones the user watched from it?',
      {
        for (final MapEntry(key: key, value: parent) in jevOptionKeys(
          taxonomy.parents,
        ).entries)
          if (!(exclude?.parent == parent &&
              exclude?.child == null &&
              taxonomy.childrenOf(parent).isEmpty))
            key: _describe(taxonomy, parent),
      },
    );

/// Which of [children] (by key) fits the channel, within [parent]; with
/// [withGeneral], "none of these" too.
JevChoice jevChildQuestion(
  String parent,
  Map<String, String> children, {
  required bool withGeneral,
}) => JevChoice(
  'Which kind of $parent best describes the videos this channel makes and '
  'the ones the user watched from it?',
  {
    ...children,
    if (withGeneral) jevGeneral: 'None of these; just $parent in general',
  },
);

/// Whether a sub-category of [parent] Claude named is one of [existing] (by
/// key) under another name.
JevChoice jevSameQuestion(String parent, Map<String, String> existing) =>
    JevChoice(
      'Is the proposed sub-category of $parent the same as one of these, '
      'under another name?',
      {...existing, jevGeneral: 'None of these; it is a different one'},
    );

/// What Jev is told to check a name Claude [proposed] under [parent].
Map<String, Object> jevSameState({
  required String proposed,
  required String parent,
  required String reason,
  required String channel,
}) => {
  'proposed_sub_category': proposed,
  'category': parent,
  'why': reason,
  'channel': channel,
};

/// A category and its sub-categories, for Jev to pick between them.
String _describe(Taxonomy taxonomy, String parent) {
  final children = taxonomy.childrenOf(parent);
  return children.isEmpty ? parent : '$parent: ${children.join(', ')}';
}

/// What Jev is asked to tag a channel: whether each of [candidates]
/// (`tag_0`…) describes it, its meaning being what yes means, and whether
/// it's also about something none of them name (`other`), which names them,
/// since Jev reads each question alone.
Map<String, JevQuestion> jevTagQuestions(List<TagCandidate> candidates) => {
  for (final (i, (key: _, :tag)) in candidates.indexed)
    'tag_$i': JevNoul(
      'Does the tag "${tag.name}" describe what this channel is about, as a '
      'viewer would tag it?',
      whenTrue: tag.meaning,
      whenFalse:
          'The tag names something else, even something related, such as '
          'another game in the same series.',
    ),
  'other': JevNoul(
    'Besides these tags: '
    '${[for (final (key: _, :tag) in candidates) tag.name].join(', ')}, is '
    'this channel also specifically about a particular game, a franchise or '
    'company, a group or agency, a kind of creator or video, or a theme that '
    'none of them name?',
    whenTrue: 'It is about something specific none of these tags name.',
    whenFalse:
        'These tags name everything specific it is about, or what is left is '
        'only its category or what most channels like it do, such as '
        'streaming, playing games or singing.',
  ),
};

/// How sure Jev is, in [answers] to [jevTagQuestions] of [candidates], that
/// each tag fits, by its key, and that the channel is about something none
/// of them name.
({Map<String, double> yes, double other}) readJevTags(
  Map<String, JevAnswer> answers,
  List<TagCandidate> candidates,
) => (
  yes: {
    for (final (i, (:key, tag: _)) in candidates.indexed)
      if (answers['tag_$i'] case NoulAnswer(:final yes)) key: yes,
  },
  other: switch (answers['other']) {
    NoulAnswer(:final yes) => yes,
    _ => 0,
  },
);
