import 'channel_emoji.dart';
import 'picker_emoji.dart';
import 'unicode_emoji.dart';

/// Most `:name` suggestions offered at once.
const maxEmojiSuggestions = 8;

/// Suggestions for a typed `:name` [fragment] (lowercase): exact matches,
/// then prefix matches, then other matches. Within each, [custom] channel
/// emojis (most used first) come before [standard] ones, so an emoji and a
/// standard one with the same name are both offered.
///
/// Leave [includeStandard] false for `:_name`, which only channel emojis use.
List<PickerEmoji> rankEmojiSuggestions(
  String fragment, {
  required Iterable<ChannelEmoji> custom,
  required List<UnicodeEmoji> standard,
  bool includeStandard = true,
}) {
  final customExact = <CustomPickerEmoji>[];
  final customPrefix = <CustomPickerEmoji>[];
  final customContains = <CustomPickerEmoji>[];
  for (final emoji in custom) {
    final name = emoji.name.toLowerCase();
    if (name == fragment) {
      customExact.add(CustomPickerEmoji(emoji));
    } else if (name.startsWith(fragment)) {
      customPrefix.add(CustomPickerEmoji(emoji));
    } else if (name.contains(fragment)) {
      customContains.add(CustomPickerEmoji(emoji));
    }
  }
  int byUsage(CustomPickerEmoji a, CustomPickerEmoji b) =>
      b.emoji.usageCount.compareTo(a.emoji.usageCount);
  customPrefix.sort(byUsage);
  customContains.sort(byUsage);

  final standardExact = <UnicodePickerEmoji>[];
  final standardPrefix = <(int, UnicodePickerEmoji)>[];
  final standardContains = <UnicodePickerEmoji>[];
  if (includeStandard) {
    for (final (i, emoji) in standard.indexed) {
      String? prefix;
      String? contains;
      for (final name in emoji.shortNames) {
        if (name == fragment) {
          standardExact.add(UnicodePickerEmoji(emoji, name));
          prefix = contains = null;
          break;
        }
        if (name.startsWith(fragment)) {
          prefix ??= name;
        } else if (name.contains(fragment)) {
          contains ??= name;
        }
      }
      if (prefix != null) {
        standardPrefix.add((i, UnicodePickerEmoji(emoji, prefix)));
      } else if (contains != null) {
        standardContains.add(UnicodePickerEmoji(emoji, contains));
      }
    }
    // Shortest names first (`:heart` → ❤️ before 😍 heart_eyes).
    standardPrefix.sort((a, b) {
      final byLength = a.$2.name.length.compareTo(b.$2.name.length);
      return byLength != 0 ? byLength : a.$1.compareTo(b.$1);
    });
  }

  return [
    ...customExact,
    ...standardExact,
    ...customPrefix,
    for (final (_, emoji) in standardPrefix) emoji,
    ...customContains,
    ...standardContains,
  ].take(maxEmojiSuggestions).toList();
}
