import 'category_path.dart';

/// Categories, each with its sub-categories: YouTube's, and the ones AI
/// made for channels YouTube's don't fit.
class Taxonomy {
  /// Sub-categories by category, in order.
  final Map<String, List<String>> children;

  const Taxonomy(this.children);

  Iterable<String> get parents => children.keys;

  List<String> childrenOf(String parent) => children[parent] ?? const [];

  bool contains(CategoryPath path) => find(path.parent, path.child) == path;

  /// The category [parent], and its sub-category [child] when given,
  /// whatever their case; null when there's no such one.
  CategoryPath? find(String parent, [String? child]) {
    final p = _match(children.keys, parent);
    if (p == null) return null;
    if (child == null) return CategoryPath(p);
    final c = _match(childrenOf(p), child);
    return c == null ? null : CategoryPath(p, c);
  }

  /// These categories with [custom] sub-categories added, each once
  /// whatever its case.
  Taxonomy withCustom(Map<String, List<String>> custom) {
    final merged = {
      for (final MapEntry(:key, :value) in children.entries) key: [...value],
    };
    for (final MapEntry(key: parent, value: kids) in custom.entries) {
      final p = _match(merged.keys, parent);
      if (p == null) continue;
      for (final kid in kids) {
        if (_match(merged[p]!, kid) == null) merged[p]!.add(kid);
      }
    }
    return Taxonomy(merged);
  }

  static String? _match(Iterable<String> names, String name) {
    final wanted = name.trim().toLowerCase();
    for (final n in names) {
      if (n.toLowerCase() == wanted) return n;
    }
    return null;
  }
}

/// YouTube's categories and sub-categories, as its channel topics name them.
const youtubeTaxonomy = Taxonomy({
  'Gaming': [
    'Action',
    'Action-adventure',
    'Casual',
    'Music games',
    'Puzzle',
    'Racing',
    'Role-playing',
    'Simulation',
    'Sports games',
    'Strategy',
  ],
  'Music': [
    'Christian',
    'Classical',
    'Country',
    'Electronic',
    'Hip hop',
    'Independent',
    'Jazz',
    'Asian music',
    'Latin music',
    'Pop',
    'Reggae',
    'R&B',
    'Rock',
    'Soul',
  ],
  'Sports': [
    'American football',
    'Baseball',
    'Basketball',
    'Boxing',
    'Cricket',
    'Football',
    'Golf',
    'Ice hockey',
    'Mixed martial arts',
    'Motorsport',
    'Wrestling',
    'Tennis',
    'Volleyball',
  ],
  'Entertainment': ['Humor', 'Movies', 'Performing arts', 'TV shows'],
  'Lifestyle': [
    'Beauty',
    'Fashion',
    'Fitness',
    'Food',
    'Hobbies',
    'Pets',
    'Technology',
    'Travel',
    'Vehicles',
  ],
  'Society': ['Business', 'Health', 'Military', 'Politics', 'Religion'],
  'Knowledge': [],
});
