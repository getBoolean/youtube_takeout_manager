import 'category_path.dart';
import 'name_key.dart';
import 'sub_category.dart';

/// Each of YouTube's categories' emoji.
const categoryEmoji = {
  'Gaming': '🎮',
  'Music': '🎵',
  'Sports': '⚽',
  'Entertainment': '🎬',
  'Lifestyle': '🏡',
  'Society': '🏛️',
  'Knowledge': '📚',
};

/// The emoji of channels with no category.
const uncategorizedEmoji = '❔';

/// The emoji of YouTube's sub-categories, by category, hand-picked.
const youtubeSubCategoryEmoji = <String, Map<String, String>>{
  'Gaming': {
    'Action': '💥',
    'Action-adventure': '🗡️',
    'Casual': '🎲',
    'Music games': '🎶',
    'Puzzle': '🧩',
    'Racing': '🏎️',
    'Role-playing': '🐉',
    'Simulation': '🛩️',
    'Sports games': '🏟️',
    'Strategy': '♟️',
  },
  'Music': {
    'Christian': '✝️',
    'Classical': '🎻',
    'Country': '🤠',
    'Electronic': '🎛️',
    'Hip hop': '🎤',
    'Independent': '💿',
    'Jazz': '🎷',
    'Asian music': '🏮',
    'Latin music': '💃',
    'Pop': '🌟',
    'Reggae': '🌴',
    'R&B': '🎙️',
    'Rock': '🎸',
    'Soul': '🎹',
  },
  'Sports': {
    'American football': '🏈',
    'Baseball': '⚾',
    'Basketball': '🏀',
    'Boxing': '🥊',
    'Cricket': '🏏',
    'Football': '⚽',
    'Golf': '⛳',
    'Ice hockey': '🏒',
    'Mixed martial arts': '🥋',
    'Motorsport': '🏁',
    'Wrestling': '🤼',
    'Tennis': '🎾',
    'Volleyball': '🏐',
  },
  'Entertainment': {
    'Humor': '😂',
    'Movies': '🎞️',
    'Performing arts': '🎭',
    'TV shows': '📺',
  },
  'Lifestyle': {
    'Beauty': '💄',
    'Fashion': '👗',
    'Fitness': '🏋️',
    'Food': '🍳',
    'Hobbies': '🧶',
    'Pets': '🐾',
    'Technology': '💻',
    'Travel': '✈️',
    'Vehicles': '🚗',
  },
  'Society': {
    'Business': '💼',
    'Health': '🩺',
    'Military': '🎖️',
    'Politics': '🗳️',
    'Religion': '🛐',
  },
};

/// [path]'s emoji: its sub-category's, YouTube's or as [custom] keeps it,
/// else its category's; [uncategorizedEmoji] without a category.
String emojiOf(
  CategoryPath? path, {
  Map<String, List<SubCategory>> custom = const {},
}) {
  if (path == null) return uncategorizedEmoji;
  final category = categoryEmoji[path.parent] ?? uncategorizedEmoji;
  final child = path.child;
  if (child == null) return category;
  if (youtubeSubCategoryEmoji[path.parent]?[child] case final youtube?) {
    return youtube;
  }
  final key = nameKey(child);
  for (final sub in custom[path.parent] ?? const <SubCategory>[]) {
    if (nameKey(sub.name) == key) return sub.emoji ?? category;
  }
  return category;
}
