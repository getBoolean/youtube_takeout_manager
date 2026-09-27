import 'channel_emoji.dart';
import 'unicode_emoji.dart';

/// An emoji the picker or `:name` autocomplete can insert into a search:
/// a channel's custom emoji or a standard one.
sealed class PickerEmoji {
  const PickerEmoji();

  /// Name without colons, used for display and matching.
  String get name;
  String get token => ':$name:';

  /// Text inserted into the search field.
  String get insertText;

  /// Stable id for Frequently Used (see [pickerEmojiForUse]).
  String get usageId;
}

// Usage id prefixes. Ids are saved on the device, so these can't change.
const _customUsage = 'c:';
const _unicodeUsage = 'u:';

final class CustomPickerEmoji extends PickerEmoji {
  final ChannelEmoji emoji;

  const CustomPickerEmoji(this.emoji);

  @override
  String get name => emoji.name;
  @override
  String get insertText => emoji.token;
  @override
  String get usageId => '$_customUsage${emoji.key}';

  @override
  bool operator ==(Object other) =>
      other is CustomPickerEmoji && other.emoji == emoji;
  @override
  int get hashCode => emoji.hashCode;
}

final class UnicodePickerEmoji extends PickerEmoji {
  final UnicodeEmoji emoji;

  /// The short name shown, e.g. the alias a `:name` search matched.
  @override
  final String name;

  UnicodePickerEmoji(this.emoji, [String? alias])
    : name = alias ?? emoji.shortName;

  @override
  String get insertText => emoji.emoji;
  @override
  String get usageId => '$_unicodeUsage${emoji.emoji}';

  @override
  bool operator ==(Object other) =>
      other is UnicodePickerEmoji &&
      other.emoji.emoji == emoji.emoji &&
      other.name == name;
  @override
  int get hashCode => Object.hash(emoji.emoji, name);
}

/// The emoji [usageId] was recorded for, if it's one of [customByKey]
/// (keyed by [ChannelEmoji.key]) or [standardByEmoji] (keyed by
/// [UnicodeEmoji.emoji]).
PickerEmoji? pickerEmojiForUse(
  String usageId, {
  required Map<String, ChannelEmoji> customByKey,
  required Map<String, UnicodeEmoji> standardByEmoji,
}) {
  if (usageId.startsWith(_unicodeUsage)) {
    final emoji = standardByEmoji[usageId.substring(_unicodeUsage.length)];
    return emoji == null ? null : UnicodePickerEmoji(emoji);
  }
  if (usageId.startsWith(_customUsage)) {
    final emoji = customByKey[usageId.substring(_customUsage.length)];
    return emoji == null ? null : CustomPickerEmoji(emoji);
  }
  return null;
}
