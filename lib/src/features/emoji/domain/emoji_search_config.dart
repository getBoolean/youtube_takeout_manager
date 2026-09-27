import 'channel_emoji.dart';
import 'unicode_emoji.dart';

/// Emojis offered by an emoji search bar: the ones used in the content it
/// searches.
class EmojiSearchConfig {
  final List<ChannelEmojiGroup> groups;

  /// Standard emojis, in picker order.
  final List<UnicodeEmoji> standardEmojis;

  const EmojiSearchConfig({required this.groups, required this.standardEmojis});

  bool get isEmpty =>
      standardEmojis.isEmpty && groups.every((g) => g.emojis.isEmpty);

  /// Every group's channel emojis, in order.
  Iterable<ChannelEmoji> get channelEmojis =>
      groups.expand((group) => group.emojis);

  /// Channel emojis keyed by lowercase name; the first with a name wins.
  Map<String, ChannelEmoji> channelEmojisByName() {
    final byName = <String, ChannelEmoji>{};
    for (final emoji in channelEmojis) {
      byName.putIfAbsent(emoji.name.toLowerCase(), () => emoji);
    }
    return byName;
  }

  /// Standard emojis keyed by each of their short names.
  Map<String, UnicodeEmoji> standardEmojisByName() => {
    for (final emoji in standardEmojis)
      for (final name in emoji.shortNames) name: emoji,
  };

  /// The title of the group for [channelId], if there is one.
  String? channelTitle(String channelId) => groups
      .where((group) => group.channelId == channelId)
      .firstOrNull
      ?.displayTitle;

  /// Screens build a new config on every rebuild from the same provider
  /// values, so configs holding the same lists are equal, without comparing
  /// every emoji.
  @override
  bool operator ==(Object other) =>
      other is EmojiSearchConfig &&
      identical(other.groups, groups) &&
      identical(other.standardEmojis, standardEmojis);

  @override
  int get hashCode =>
      Object.hash(identityHashCode(groups), identityHashCode(standardEmojis));
}
