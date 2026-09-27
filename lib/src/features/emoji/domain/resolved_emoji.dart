import 'emoji_shortcode.dart';

/// A custom emoji name learned from YouTube's live chat data.
class ResolvedEmoji {
  /// Name without colons or leading underscore, e.g. `shortsad`.
  final String name;

  /// Channel that owns the emoji (prefix of YouTube's `emojiId`).
  final String? ownerChannelId;

  const ResolvedEmoji({required this.name, this.ownerChannelId});

  static ResolvedEmoji? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final owner = json['owner'];
    if (name is! String || !isValidEmojiName(name)) return null;
    return ResolvedEmoji(
      name: name,
      ownerChannelId: owner is String ? owner : null,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'owner': ownerChannelId};
}
