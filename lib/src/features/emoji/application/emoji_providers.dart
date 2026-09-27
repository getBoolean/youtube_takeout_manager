import 'dart:collection';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/search_options_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_options_state.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/comment_segments.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import '../data/unicode_emoji_catalog.dart';
import '../domain/channel_emoji.dart';
import '../domain/emoji_key.dart';
import '../domain/unicode_emoji.dart';
import 'emoji_names.dart';

part 'emoji_providers.g.dart';

/// The emojis in one channel's comments and live chats. Filled in by
/// [channelEmojiScans]; read-only after that.
class ChannelEmojiScan {
  final _customCounts = <String, int>{};
  final _customUrls = <String, String>{};
  final _standardEmojis = <UnicodeEmoji>{};
  final _videoIds = <String>{};

  /// Uses of each custom emoji, keyed by `emojiKey`, in the order first
  /// seen.
  late final Map<String, int> customCounts = UnmodifiableMapView(_customCounts);

  /// A Takeout URL of each custom emoji, keyed by `emojiKey`.
  late final Map<String, String> customUrls = UnmodifiableMapView(_customUrls);

  /// Standard emojis in the text: the ones a search would find (see
  /// [UnicodeEmojiCatalog.find]).
  late final Set<UnicodeEmoji> standardEmojis = UnmodifiableSetView(
    _standardEmojis,
  );

  /// Videos the comments and live chats were posted on.
  late final Set<String> videoIds = UnmodifiableSetView(_videoIds);

  void _add(Interaction item) {
    if (item.videoId case final videoId?) _videoIds.add(videoId);
    final raw = item.rawText;
    final mayHaveCustom = raw.contains('customEmojiUrl');
    final mayHaveStandard = _hasNonAscii(raw);
    if (!mayHaveCustom && !mayHaveStandard) return;
    for (final segment in parseCommentSegments(raw)) {
      switch (segment) {
        case EmojiSegment(:final url) when mayHaveCustom:
          final key = emojiKey(url);
          _customUrls.putIfAbsent(key, () => url);
          _customCounts[key] = (_customCounts[key] ?? 0) + 1;
        case TextSegment(:final text) when mayHaveStandard:
          _addUnicodeEmojis(text, _standardEmojis);
        case _:
          break;
      }
    }
  }
}

/// Each channel's comments and live chats read for emojis, parsing each one
/// once.
@Riverpod(keepAlive: true)
Map<String, ChannelEmojiScan> channelEmojiScans(Ref ref) {
  final result = <String, ChannelEmojiScan>{};
  for (final kind in QueueItemKind.values) {
    ref.watch(interactionsByChannelProvider(kind)).forEach((channelId, items) {
      final scan = result.putIfAbsent(channelId, ChannelEmojiScan.new);
      items.forEach(scan._add);
    });
  }
  return UnmodifiableMapView(result);
}

/// Custom emojis used in each channel's comments and live chats, most used
/// first.
@Riverpod(keepAlive: true)
Map<String, List<ChannelEmoji>> channelEmojis(Ref ref) {
  final names = ref.watch(emojiNamesByKeyProvider);
  return {
    for (final MapEntry(key: channelId, value: scan)
        in ref.watch(channelEmojiScansProvider).entries)
      if (scan.customCounts.isNotEmpty)
        channelId: [
          for (final MapEntry(:key, value: count) in scan.customCounts.entries)
            ChannelEmoji(
              key: key,
              url: scan.customUrls[key]!,
              name: names[key] ?? fallbackEmojiName(key),
              channelId: channelId,
              usageCount: count,
              resolved: names.containsKey(key),
            ),
        ]..sort((a, b) => b.usageCount.compareTo(a.usageCount)),
  };
}

/// Emoji picker sections for every channel with custom emojis, in the same
/// order as the channel list.
@riverpod
List<ChannelEmojiGroup> allChannelEmojiGroups(Ref ref) {
  final emojis = ref.watch(channelEmojisProvider);
  return [
    for (final channel in ref.watch(channelsProvider))
      if (emojis[channel.channelId] case final list?)
        _group(channel.channelId, channel, list),
  ];
}

/// Emoji picker section for a single channel (empty if it has no emojis).
@riverpod
List<ChannelEmojiGroup> channelEmojiGroups(Ref ref, String channelId) {
  final emojis = ref.watch(channelEmojisProvider)[channelId];
  if (emojis == null) return const [];
  final channel = ref.watch(channelByIdProvider(channelId));
  return [_group(channelId, channel, emojis)];
}

ChannelEmojiGroup _group(
  String channelId,
  Channel? channel,
  List<ChannelEmoji> emojis,
) => ChannelEmojiGroup(
  channelId: channelId,
  channelTitle: channel?.channelTitle,
  thumbnailUrl: channel?.thumbnailUrl,
  emojis: emojis,
);

/// Standard emojis in the titles of each channel's videos that have the
/// user's comments or live chats, which a channel search can match.
@Riverpod(keepAlive: true)
Map<String, Set<UnicodeEmoji>> titleUnicodeEmojisByChannel(Ref ref) {
  final videos = ref.watch(videoMetadataProvider).value ?? const {};
  final result = <String, Set<UnicodeEmoji>>{};
  ref.watch(channelEmojiScansProvider).forEach((channelId, scan) {
    final emojis = <UnicodeEmoji>{};
    for (final id in scan.videoIds) {
      final title = videos[id]?.title;
      if (title != null && _hasNonAscii(title)) {
        _addUnicodeEmojis(title, emojis);
      }
    }
    if (emojis.isNotEmpty) result[channelId] = emojis;
  });
  return result;
}

/// Standard emojis used in any comment or live chat, in picker order.
@riverpod
List<UnicodeEmoji> allUsedUnicodeEmojis(Ref ref) => _inPickerOrder({
  for (final scan in ref.watch(channelEmojiScansProvider).values)
    ...scan.standardEmojis,
});

/// Standard emojis a search of [channelId] can find, in picker order: those
/// in its comments and live chats, and in its video titles while the search
/// matches them.
@riverpod
List<UnicodeEmoji> channelUnicodeEmojis(Ref ref, String channelId) {
  final matchTitles =
      ref.watch(searchOptionsProvider).value?.matchGroupTitles ??
      const SearchOptionsState().matchGroupTitles;
  return _inPickerOrder({
    ...?ref.watch(channelEmojiScansProvider)[channelId]?.standardEmojis,
    if (matchTitles)
      ...?ref.watch(titleUnicodeEmojisByChannelProvider)[channelId],
  });
}

List<UnicodeEmoji> _inPickerOrder(Set<UnicodeEmoji> used) {
  if (used.isEmpty) return const [];
  return [
    for (final emoji in unicodeEmojiCatalog.all)
      if (used.contains(emoji)) emoji,
  ];
}

/// Adds the standard emojis in [text] that a search would find (see
/// [UnicodeEmojiCatalog.find]) to [into].
void _addUnicodeEmojis(String text, Set<UnicodeEmoji> into) {
  for (final char in text.characters) {
    if (unicodeEmojiCatalog.find(char) case final emoji?) into.add(emoji);
  }
}

/// Whether [raw] may contain emojis: non-ASCII text, or a JSON escape of it.
bool _hasNonAscii(String raw) {
  for (final unit in raw.codeUnits) {
    if (unit > 0x7F) return true;
  }
  return raw.contains(r'\u');
}
