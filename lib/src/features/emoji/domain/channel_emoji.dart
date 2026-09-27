import 'package:dart_mappable/dart_mappable.dart';

part 'channel_emoji.mapper.dart';

/// A custom channel emoji found in the user's Takeout comments/live chats.
@MappableClass()
class ChannelEmoji with ChannelEmojiMappable {
  /// See `emojiKey` in emoji_key.dart.
  final String key;
  final String url;

  /// Name without colons or YouTube's leading underscore, e.g. `shortsad`.
  final String name;
  final String channelId;
  final int usageCount;

  /// False when [name] is a generated fallback.
  final bool resolved;

  const ChannelEmoji({
    required this.key,
    required this.url,
    required this.name,
    required this.channelId,
    required this.usageCount,
    required this.resolved,
  });

  String get token => ':$name:';
}

/// A channel's emojis, as shown in one section of the emoji picker.
@MappableClass()
class ChannelEmojiGroup with ChannelEmojiGroupMappable {
  final String channelId;
  final String? channelTitle;
  final String? thumbnailUrl;
  final List<ChannelEmoji> emojis;

  const ChannelEmojiGroup({
    required this.channelId,
    this.channelTitle,
    this.thumbnailUrl,
    required this.emojis,
  });

  String get displayTitle => channelTitle ?? channelId;
}
