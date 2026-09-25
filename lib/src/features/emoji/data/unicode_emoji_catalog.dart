import '../domain/unicode_emoji.dart';
import 'unicode_emoji_data.dart';

/// All standard emojis offered by the picker and `:name` autocomplete.
final unicodeEmojiCatalog = UnicodeEmojiCatalog(unicodeEmojiRows);

/// Standard emojis parsed from generated rows (see
/// `tool/generate_unicode_emojis.dart`). Parsed on first use.
class UnicodeEmojiCatalog {
  final Map<UnicodeEmojiCategory, List<String>> _rows;

  UnicodeEmojiCatalog(this._rows);

  /// Emojis per category, in picker order.
  late final Map<UnicodeEmojiCategory, List<UnicodeEmoji>> byCategory = {
    for (final MapEntry(key: category, value: rows) in _rows.entries)
      category: [for (final row in rows) _parse(row, category)],
  };

  late final List<UnicodeEmoji> all = [
    for (final emojis in byCategory.values) ...emojis,
  ];

  /// Keyed by every short name (lowercase).
  late final Map<String, UnicodeEmoji> byShortName = {
    for (final emoji in all)
      for (final name in emoji.shortNames) name: emoji,
  };

  /// Keyed by the emoji itself.
  late final Map<String, UnicodeEmoji> byEmoji = {
    for (final emoji in all) emoji.emoji: emoji,
  };

  late final Map<String, UnicodeEmoji> _byFolded = {
    for (final emoji in all) _withoutSelector(emoji.emoji): emoji,
  };

  /// The emoji that a search for would find [char] (one user-perceived
  /// character): ignoring U+FE0F, and a trailing skin tone (a search for 👍
  /// finds 👍🏽). Null for text and unknown emojis.
  UnicodeEmoji? find(String char) {
    final folded = _withoutSelector(char);
    if (_byFolded[folded] case final emoji?) return emoji;
    final runes = folded.runes.toList();
    if (runes.length == 2 && _isSkinTone(runes[1])) {
      return _byFolded[String.fromCharCode(runes[0])];
    }
    return null;
  }

  static String _withoutSelector(String text) =>
      text.replaceAll('\u{FE0F}', '');

  static bool _isSkinTone(int rune) => rune >= 0x1F3FB && rune <= 0x1F3FF;

  static UnicodeEmoji _parse(String row, UnicodeEmojiCategory category) {
    final [emoji, names, name] = row.split('\t');
    return UnicodeEmoji(
      emoji: emoji,
      shortNames: names.split(' '),
      name: name,
      category: category,
    );
  }
}
