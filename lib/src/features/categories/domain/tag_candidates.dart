import 'categorization_plan.dart';
import 'category_path.dart';
import 'channel_category.dart';
import 'channel_evidence.dart';
import 'name_key.dart';
import 'sub_category.dart';
import 'tag_name.dart';

/// The most AI-named tags Jev is asked about for a channel; the user's
/// tags come on top.
const maxAiTagCandidates = 60;

/// How sure Jev must be that a channel is about something no tag names
/// for Claude to be asked: below [jevThreshold], since missing a tag costs
/// more than asking.
const otherThreshold = 0.5;

/// How unsure Jev must be that a tag still fits for a check to take it
/// off: below [jevThreshold], so a tag doesn't come and go.
const tagRemoveBelow = 0.4;

/// A tag Jev may be asked about, by its folded name.
typedef TagCandidate = ({String key, TagName tag});

/// The most words a tag can have to be found named in a channel's text.
const _longestNamed = 6;

/// [hash] of the words before, carried on with [word]: the same words in
/// the same order hash the same, wherever they are.
int _sequenceHash(int hash, String word) =>
    (hash * 31 + word.hashCode) & 0x3fffffff;

/// The tags there are, ready to pick a channel's candidates from: the
/// user's that AI may use, and AI's, with how many channels have each,
/// overall and by category, and AI's by their first word, so a channel's
/// text is read once whatever the number of tags. Made [at] a time: what a
/// channel's tags are made or checked against.
class TagIndex {
  final DateTime at;
  final List<TagCandidate> _users;
  final Map<String, TagName> _names;
  final Map<String, int> _uses;
  final List<String> _mostUsed;
  final Map<String, List<String>> _mostUsedIn;

  /// AI's tags by [_sequenceHash] of their words, with the words.
  final Map<int, List<(String, List<String>)>> _bySequence;

  TagIndex._(
    this.at,
    this._users,
    this._names,
    this._uses,
    this._mostUsed,
    this._mostUsedIn,
    this._bySequence,
  );

  /// The index of the tags [names], as channels' [categories] use them.
  factory TagIndex.of(
    Map<String, TagName> names,
    Map<String, ChannelCategory> categories, {
    DateTime? at,
  }) {
    final uses = <String, int>{};
    final usesIn = <String, Map<String, int>>{};
    for (final category in categories.values) {
      for (final tag in category.tags) {
        final key = nameKey(tag);
        uses[key] = (uses[key] ?? 0) + 1;
        if (category.path case CategoryPath(:final parent)) {
          final inParent = usesIn.putIfAbsent(parent, () => {});
          inParent[key] = (inParent[key] ?? 0) + 1;
        }
      }
    }
    final ai = <String>[];
    final users = <TagCandidate>[];
    final bySequence = <int, List<(String, List<String>)>>{};
    for (final MapEntry(:key, value: tag) in names.entries) {
      if (!tag.offeredToAi) continue;
      if (tag.origin == NameOrigin.user) {
        users.add((key: key, tag: tag));
        continue;
      }
      ai.add(key);
      final words = nameKeyWords(tag.name);
      if (words.isNotEmpty && words.length <= _longestNamed) {
        var hash = 0;
        for (final word in words) {
          hash = _sequenceHash(hash, word);
        }
        bySequence.putIfAbsent(hash, () => []).add((key, words));
      }
    }
    int Function(String, String) byUse(Map<String, int> counts) => (a, b) {
      final byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      return byCount != 0 ? byCount : names[a]!.name.compareTo(names[b]!.name);
    };
    users.sort((a, b) => byUse(uses)(a.key, b.key));
    final aiKeys = ai.toSet();
    return TagIndex._(
      (at ?? DateTime.now()).toUtc(),
      users,
      names,
      uses,
      ai..sort(byUse(uses)),
      {
        for (final MapEntry(key: parent, value: counts) in usesIn.entries)
          parent: [
            for (final key in counts.keys)
              if (aiKeys.contains(key)) key,
          ]..sort(byUse(counts)),
      },
      bySequence,
    );
  }

  /// Every tag there is, by its folded name.
  Map<String, TagName> get names => _names;

  /// The tags Claude is told of, to reuse: every tag of the user's that AI
  /// may use, with its meaning, then at most [most] of AI's, the most used
  /// first, by name.
  List<NamedTag> knownForClaude({int most = 200}) => [
    for (final (key: _, :tag) in _users) (name: tag.name, meaning: tag.meaning),
    for (final key in _mostUsed.take(most))
      (name: _names[key]!.name, meaning: null),
  ];

  /// When a tag of the user's that AI may use was last defined or changed:
  /// a channel checked before then is checked again.
  DateTime? get userTagsChangedAt {
    DateTime? newest;
    for (final (key: _, :tag) in _users) {
      final changed = tag.changedAt;
      if (changed != null && (newest == null || changed.isAfter(newest))) {
        newest = changed;
      }
    }
    return newest;
  }

  /// The user's tags AI may use that were defined or changed after
  /// [checkedAt], or all of them when never checked: what a check asks
  /// about.
  List<TagCandidate> changedSince(DateTime? checkedAt) => [
    for (final candidate in _users)
      if (checkedAt == null ||
          (candidate.tag.changedAt?.isAfter(checkedAt) ?? false))
        candidate,
  ];

  /// The tags to ask Jev about for the channel [evidence] tells of, in
  /// [category]: every tag of the user's that AI may use, then at most
  /// [maxAi] of AI's: those named in its name, description or titles, the
  /// most used first, then the most used in its category, then the most
  /// used overall.
  List<TagCandidate> candidatesFor(
    ChannelEvidence evidence,
    CategoryPath? category, {
    int maxAi = maxAiTagCandidates,
  }) {
    final named = <String>{};
    for (final text in [
      evidence.title,
      ?evidence.description,
      ...evidence.titles,
    ]) {
      final words = nameKeyWords(text);
      for (var i = 0; i < words.length; i++) {
        var hash = 0;
        for (var n = 1; n <= _longestNamed && i + n <= words.length; n++) {
          hash = _sequenceHash(hash, words[i + n - 1]);
          for (final (key, tagWords)
              in _bySequence[hash] ?? const <(String, List<String>)>[]) {
            if (tagWords.length != n) continue;
            var matches = true;
            for (var j = 0; j < n && matches; j++) {
              matches = words[i + j] == tagWords[j];
            }
            if (matches) named.add(key);
          }
        }
      }
    }
    final picked = <String>{};
    final ai = <String>[];
    void offer(Iterable<String> keys) {
      for (final key in keys) {
        if (ai.length >= maxAi) return;
        if (picked.add(key)) ai.add(key);
      }
    }

    offer(
      named.toList()..sort((a, b) => (_uses[b] ?? 0).compareTo(_uses[a] ?? 0)),
    );
    if (category != null) offer(_mostUsedIn[category.parent] ?? const []);
    offer(_mostUsed);
    return [..._users, for (final key in ai) (key: key, tag: _names[key]!)];
  }
}

/// The tags a channel keeps from Jev's [kept] (each with how sure it was)
/// and what Claude [added]: the user's that Jev kept, the surest first,
/// and the user's Claude named; then AI's Jev kept, the surest first, and
/// Claude's others, in its order. Each once by `nameKey`, spelled as [names]
/// have them, at most [maxTags]. Whose a tag is is what [names] say now.
List<String> rankTags(
  List<(TagCandidate, double)> kept,
  List<String> added,
  Map<String, TagName> names,
) {
  bool users(String key) => names[key]?.origin == NameOrigin.user;
  String spelled(String name) => names[nameKey(name)]?.name ?? name;
  final surest = [...kept]..sort((a, b) => b.$2.compareTo(a.$2));
  final ordered = [
    for (final (candidate, _) in surest)
      if (users(candidate.key)) candidate.tag.name,
    for (final name in added)
      if (users(nameKey(name))) spelled(name),
    for (final (candidate, _) in surest)
      if (!users(candidate.key)) candidate.tag.name,
    for (final name in added)
      if (!users(nameKey(name))) spelled(name),
  ];
  final keys = <String>{};
  return [
    for (final tag in ordered)
      if (keys.add(nameKey(tag))) tag,
  ].take(maxTags).toList();
}

/// [current] after Jev checked the user's tags [yes] gives how sure it is
/// of, by key: one it's sure of (at least [jevThreshold]) is added, unless
/// the user took it off this channel ([removedByUser]); one there that it's
/// sure no longer fits (below [tagRemoveBelow]) comes off, unless the user
/// put it there ([protectedKeys]). The user's tags come first, the added
/// after those there; past [maxTags], the last AI tags the user didn't put
/// there drop, and with none to drop, the last added don't come.
List<String> applyTagCheck(
  List<String> current,
  Map<String, double> yes,
  Map<String, TagName> names, {
  Set<String> protectedKeys = const {},
  Set<String> removedByUser = const {},
}) {
  bool users(String tag) => names[nameKey(tag)]?.origin == NameOrigin.user;
  final kept = [
    for (final tag in current)
      if ((yes[nameKey(tag)] ?? 1) >= tagRemoveBelow ||
          protectedKeys.contains(nameKey(tag)))
        tag,
  ];
  final have = {for (final tag in kept) nameKey(tag)};
  final adding = [
    for (final MapEntry(:key, value: sure)
        in yes.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      if (sure >= jevThreshold &&
          !have.contains(key) &&
          !removedByUser.contains(key))
        if (names[key] case final tag? when !tag.deleted) tag.name,
  ];
  final result = [
    for (final tag in kept)
      if (users(tag)) tag,
    ...adding,
    for (final tag in kept)
      if (!users(tag)) tag,
  ];
  while (result.length > maxTags) {
    final ai = result.lastIndexWhere(
      (tag) => !users(tag) && !protectedKeys.contains(nameKey(tag)),
    );
    final last = ai >= 0 ? ai : result.lastIndexWhere(adding.contains);
    if (last < 0) break;
    result.removeAt(last);
  }
  return result;
}
