import 'category_path.dart';
import 'name_key.dart';

/// Categories, each with its sub-categories: YouTube's, and the ones AI
/// made for channels YouTube's don't fit.
class Taxonomy {
  /// Sub-categories by category, in order.
  final Map<String, List<String>> children;

  const Taxonomy(this.children);

  Iterable<String> get parents => children.keys;

  List<String> childrenOf(String parent) => children[parent] ?? const [];

  /// Whether [path] is here, spelled as it is here.
  bool contains(CategoryPath path) => find(path.parent, path.child) == path;

  /// The category [parent], and its sub-category [child] when given, as
  /// spelled here, whatever their case, accents, hyphens, spaces or
  /// punctuation; null when there's no such one.
  CategoryPath? find(String parent, [String? child]) {
    final p = _index.parents[nameKey(parent)];
    if (p == null) return null;
    if (child == null) return CategoryPath(p.name);
    final c = p.children[nameKey(child)];
    return c == null ? null : CategoryPath(p.name, c);
  }

  /// These categories with [custom] sub-categories added, each once, as
  /// first spelled: a variant of one here, by [nameKey], isn't added.
  Taxonomy withCustom(Map<String, List<String>> custom) {
    final merged = {
      for (final MapEntry(:key, :value) in children.entries) key: [...value],
    };
    final keys = {
      for (final MapEntry(:key, :value) in children.entries)
        key: {for (final child in value) nameKey(child)},
    };
    for (final MapEntry(key: parent, value: kids) in custom.entries) {
      final p = find(parent)?.parent;
      if (p == null) continue;
      for (final kid in kids) {
        if (keys[p]!.add(nameKey(kid))) merged[p]!.add(kid);
      }
    }
    return Taxonomy(merged);
  }

  /// The names by key, worked out once per taxonomy.
  static final _indexes = Expando<_Index>();
  _Index get _index => _indexes[this] ??= _Index(children);
}

/// Each category, by [nameKey], with its sub-categories by [nameKey]; the
/// first spelling of a key wins.
class _Index {
  final parents = <String, ({String name, Map<String, String> children})>{};

  _Index(Map<String, List<String>> children) {
    for (final MapEntry(key: parent, value: kids) in children.entries) {
      final byKey = <String, String>{};
      for (final kid in kids) {
        byKey.putIfAbsent(nameKey(kid), () => kid);
      }
      parents.putIfAbsent(
        nameKey(parent),
        () => (name: parent, children: byKey),
      );
    }
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
