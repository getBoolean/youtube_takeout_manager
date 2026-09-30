import 'package:flutter/foundation.dart';

import 'category_path.dart';

/// A row of the viewing mix, picked to narrow the watched videos to its
/// channels: a whole category, one sub-category, the channels known only by
/// a category, or the channels not categorized.
@immutable
class CategoryPick {
  /// Null for the channels not categorized.
  final String? parent;
  final String? child;
  final bool _whole;

  /// All of [parent], whatever the sub-category.
  const CategoryPick.category(String this.parent) : child = null, _whole = true;

  const CategoryPick.uncategorized()
    : parent = null,
      child = null,
      _whole = false;

  /// [path]'s row: its sub-category, or, without one, the channels known
  /// only by its category.
  CategoryPick.of(CategoryPath path)
    : parent = path.parent,
      child = path.child,
      _whole = false;

  /// Whether this is all of a category.
  bool get isCategory => _whole;

  /// Whether a channel in [path] (null when not categorized) is picked.
  bool matches(CategoryPath? path) => switch (parent) {
    null => path == null,
    final parent =>
      path != null && path.parent == parent && (_whole || path.child == child),
  };

  /// What this is, in full.
  String get label => switch ((parent, child)) {
    (null, _) => 'Uncategorized',
    (final parent?, null) when _whole => parent,
    (final parent?, null) => '$parent (general)',
    (final parent?, final child?) => '$parent › $child',
  };

  /// What this is under its category: the sub-category alone.
  String get shortLabel => child ?? label;

  @override
  bool operator ==(Object other) =>
      other is CategoryPick &&
      other.parent == parent &&
      other.child == child &&
      other._whole == _whole;

  @override
  int get hashCode => Object.hash(parent, child, _whole);
}

/// How much of what was watched is [pick]: its channels' watched videos,
/// their [share] of all of them, and how many channels it has, counting
/// ones subscribed to but never watched. A category has its sub-categories
/// as [children], largest first.
class CategoryShare {
  final CategoryPick pick;
  final int watchCount;
  final int channelCount;

  /// Of every watched video, from 0 to 1.
  final double share;
  final List<CategoryShare> children;

  const CategoryShare({
    required this.pick,
    required this.watchCount,
    required this.channelCount,
    required this.share,
    this.children = const [],
  });
}

/// A channel of the viewing mix, by key, and how many of its videos count.
typedef MixChannel = ({String key, int count});

/// What was watched by category, largest first, with the channels not
/// categorized last: every channel of [channels], in the category
/// [categoryOf] gives it (null when it has none). Channels known only by a
/// category have a row of their own among its sub-categories, unless
/// there's nothing else in it.
List<CategoryShare> computeViewingMix({
  required Iterable<MixChannel> channels,
  required CategoryPath? Function(String key) categoryOf,
}) {
  final watches = <CategoryPath?, int>{};
  final channelCounts = <CategoryPath?, int>{};
  var total = 0;
  for (final (:key, :count) in channels) {
    final path = categoryOf(key);
    watches[path] = (watches[path] ?? 0) + count;
    channelCounts[path] = (channelCounts[path] ?? 0) + 1;
    total += count;
  }
  double shareOf(int count) => total == 0 ? 0 : count / total;

  int largestFirst(CategoryShare a, CategoryShare b) {
    final byWatches = b.watchCount.compareTo(a.watchCount);
    if (byWatches != 0) return byWatches;
    final byChannels = b.channelCount.compareTo(a.channelCount);
    if (byChannels != 0) return byChannels;
    return a.pick.label.compareTo(b.pick.label);
  }

  final leavesByParent = <String, List<CategoryShare>>{};
  for (final path in watches.keys) {
    if (path == null) continue;
    final count = watches[path]!;
    leavesByParent
        .putIfAbsent(path.parent, () => [])
        .add(
          CategoryShare(
            pick: CategoryPick.of(path),
            watchCount: count,
            channelCount: channelCounts[path]!,
            share: shareOf(count),
          ),
        );
  }

  final categories = [
    for (final MapEntry(key: parent, value: leaves) in leavesByParent.entries)
      () {
        final count = leaves.fold(0, (sum, s) => sum + s.watchCount);
        final onlyGeneral =
            leaves.length == 1 && leaves.single.pick.child == null;
        return CategoryShare(
          pick: CategoryPick.category(parent),
          watchCount: count,
          channelCount: leaves.fold(0, (sum, s) => sum + s.channelCount),
          share: shareOf(count),
          children: onlyGeneral ? const [] : (leaves..sort(largestFirst)),
        );
      }(),
  ]..sort(largestFirst);

  return [
    ...categories,
    if (channelCounts[null] case final uncategorized?)
      CategoryShare(
        pick: const CategoryPick.uncategorized(),
        watchCount: watches[null]!,
        channelCount: uncategorized,
        share: shareOf(watches[null]!),
      ),
  ];
}

/// Whether [row] is picked by [picks]: yes when it or its whole category
/// is, partly (null) when some of its sub-categories are.
bool? pickState(Set<CategoryPick> picks, CategoryShare row) {
  final parent = row.pick.parent;
  if (picks.contains(row.pick) ||
      picks.any((p) => p.isCategory && p.parent == parent)) {
    return true;
  }
  if (row.pick.isCategory && picks.any((p) => p.parent == parent)) {
    return null;
  }
  return false;
}

/// [picks] with [pick], a row of [category] or [category] itself, ticked
/// or unticked. A whole category covers its sub-categories: ticking one off
/// keeps the rest, and ticking every one picks the category.
Set<CategoryPick> togglePick(
  Set<CategoryPick> picks,
  CategoryPick pick,
  CategoryShare category,
) {
  final whole = category.pick;
  final mine = {
    for (final p in picks)
      if (p.parent == whole.parent) p,
  };
  final others = picks.difference(mine);
  if (pick == whole) {
    return pickState(picks, category) ?? false ? others : {...others, whole};
  }
  final leaves = [for (final row in category.children) row.pick];
  final picked = mine.contains(whole) ? leaves.toSet() : mine;
  if (!picked.remove(pick)) picked.add(pick);
  return {
    ...others,
    ...(leaves.isNotEmpty && picked.containsAll(leaves) ? {whole} : picked),
  };
}
