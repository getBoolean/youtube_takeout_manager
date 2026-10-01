import 'category_path.dart';
import 'channel_category.dart';
import 'name_key.dart';
import 'youtube_taxonomy.dart';

/// Channels' categories by channel key, and the sub-categories AI made, by
/// category, as kept.
typedef StoredNames = ({
  Map<String, ChannelCategory> categories,
  Map<String, List<String>> custom,
});

/// [stored] with sub-category names that differ only by case, accents,
/// hyphens, spaces or punctuation ([nameKey]) under the same category made
/// one. [builtIn]'s spelling always wins, and leaves the AI-made list;
/// otherwise the spelling the most channels have wins, ties going to the
/// AI-made list's order, then to the spelling a channel had first. Every
/// channel and runner-up moves to it; what changes nothing is given back as
/// it was, so saving writes only what changed. Merging again changes
/// nothing.
StoredNames mergeNameVariants(
  StoredNames stored, {
  Taxonomy builtIn = youtubeTaxonomy,
}) {
  final variants = _Variants();
  for (final parent in builtIn.parents) {
    for (final child in builtIn.childrenOf(parent)) {
      variants.of(parent, child).builtIn = true;
    }
  }
  for (final MapEntry(key: parent, value: children) in stored.custom.entries) {
    for (final (i, child) in children.indexed) {
      variants.of(parent, child).listed ??= i;
    }
  }
  for (final category in stored.categories.values) {
    if (category.path case CategoryPath(:final parent, child: final child?)) {
      variants.of(parent, child)
        ..used += 1
        ..seen(category.decidedAt);
    }
    for (final runnerUp in category.runnersUp) {
      if (runnerUp.path case CategoryPath(:final parent, child: final child?)) {
        variants.of(parent, child).seen(category.decidedAt);
      }
    }
  }
  final renamed = variants.renamed();

  CategoryPath? rename(CategoryPath? path) {
    if (path case CategoryPath(:final parent, child: final child?)) {
      if (renamed[(parent, child)] case final winner?) {
        return CategoryPath(parent, winner);
      }
    }
    return path;
  }

  final categories = <String, ChannelCategory>{};
  for (final MapEntry(:key, value: category) in stored.categories.entries) {
    final path = rename(category.path);
    var changed = !identical(path, category.path);
    final runnersUp = <ScoredPath>[];
    final had = <CategoryPath>{};
    for (final runnerUp in category.runnersUp) {
      final moved = rename(runnerUp.path)!;
      if (!had.add(moved)) {
        changed = true;
        continue;
      }
      if (identical(moved, runnerUp.path)) {
        runnersUp.add(runnerUp);
      } else {
        changed = true;
        runnersUp.add(ScoredPath(path: moved, score: runnerUp.score));
      }
    }
    categories[key] = changed
        ? category.copyWith(path: path, runnersUp: runnersUp)
        : category;
  }

  final custom = <String, List<String>>{};
  for (final MapEntry(key: parent, value: children) in stored.custom.entries) {
    final keys = <String>{};
    final kept = <String>[];
    for (final child in children) {
      final winner = renamed[(parent, child)] ?? child;
      if (variants.isBuiltIn(parent, winner)) continue;
      if (keys.add(nameKey(winner))) kept.add(winner);
    }
    if (kept.isEmpty) continue;
    var same = kept.length == children.length;
    for (var i = 0; same && i < kept.length; i++) {
      same = kept[i] == children[i];
    }
    custom[parent] = same ? children : kept;
  }
  return (categories: categories, custom: custom);
}

/// One spelling of a sub-category, and what's known of it.
class _Variant {
  final String spelling;
  bool builtIn = false;

  /// Its place in the AI-made list, if it's there.
  int? listed;

  /// How many channels have it.
  int used = 0;

  /// When the first channel that names it was categorized.
  DateTime? firstSeen;

  _Variant(this.spelling);

  void seen(DateTime at) {
    if (firstSeen case final first? when !at.isBefore(first)) return;
    firstSeen = at;
  }

  /// Whether this spelling wins over [other].
  bool beats(_Variant other) {
    if (builtIn != other.builtIn) return builtIn;
    if (used != other.used) return used > other.used;
    if (listed != other.listed) {
      return other.listed == null ||
          (listed != null && listed! < other.listed!);
    }
    final (mine, theirs) = (firstSeen, other.firstSeen);
    if (mine == null || theirs == null) return theirs == null && mine != null;
    return mine.isBefore(theirs);
  }
}

/// Every spelling of each sub-category, by category and [nameKey].
class _Variants {
  final _byParent = <String, Map<String, Map<String, _Variant>>>{};

  _Variant of(String parent, String spelling) => _byParent
      .putIfAbsent(parent, () => {})
      .putIfAbsent(nameKey(spelling), () => {})
      .putIfAbsent(spelling, () => _Variant(spelling));

  bool isBuiltIn(String parent, String spelling) =>
      _byParent[parent]?[nameKey(spelling)]?.values.any((v) => v.builtIn) ??
      false;

  /// The winning spelling of every one that doesn't win, by category and
  /// spelling.
  Map<(String, String), String> renamed() {
    final renamed = <(String, String), String>{};
    for (final MapEntry(key: parent, value: byKey) in _byParent.entries) {
      for (final spellings in byKey.values) {
        if (spellings.length < 2) continue;
        final winner = spellings.values.reduce((a, b) => b.beats(a) ? b : a);
        for (final variant in spellings.values) {
          if (!identical(variant, winner)) {
            renamed[(parent, variant.spelling)] = winner.spelling;
          }
        }
      }
    }
    return renamed;
  }
}
