import 'package:dart_mappable/dart_mappable.dart';

part 'emoji_use.mapper.dart';

/// How often and how recently an emoji was inserted into a search, for the
/// picker's Frequently Used section.
@MappableClass()
class EmojiUse with EmojiUseMappable {
  /// See `PickerEmoji.usageId`.
  final String id;
  final int count;
  final DateTime lastUsed;

  const EmojiUse({
    required this.id,
    required this.count,
    required this.lastUsed,
  });
}
