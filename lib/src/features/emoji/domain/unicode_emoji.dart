/// Emoji picker categories, named and ordered like Discord's.
///
/// Kept free of Flutter imports so `tool/generate_unicode_emojis.dart` can use
/// it.
enum UnicodeEmojiCategory {
  people('People'),
  nature('Nature'),
  food('Food'),
  activities('Activities'),
  travel('Travel'),
  objects('Objects'),
  symbols('Symbols'),
  flags('Flags');

  final String label;

  const UnicodeEmojiCategory(this.label);
}

/// A standard Unicode emoji, e.g. 🔥 `:fire:`.
class UnicodeEmoji {
  /// The emoji itself, fully qualified (❤️ includes U+FE0F).
  final String emoji;

  /// Lowercase `:name:` shortcodes, most common first, e.g. `fire`.
  final List<String> shortNames;

  /// Unicode name, e.g. `fire`, `large red circle`.
  final String name;
  final UnicodeEmojiCategory category;

  const UnicodeEmoji({
    required this.emoji,
    required this.shortNames,
    required this.name,
    required this.category,
  });

  String get shortName => shortNames.first;
  String get token => ':$shortName:';
}
