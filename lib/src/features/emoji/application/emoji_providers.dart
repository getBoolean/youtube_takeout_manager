import 'dart:convert';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/search_options_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_options_state.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../data/emoji_name_cache_repository.dart';
import '../data/unicode_emoji_catalog.dart';
import '../data/youtube_emoji_name_repository.dart';
import '../domain/channel_emoji.dart';
import '../domain/emoji_use.dart';
import '../domain/unicode_emoji.dart';

part 'emoji_providers.g.dart';

class EmojiNamesState {
  final Map<String, ResolvedEmoji> names;
  final bool isResolving;

  /// True when lookups are paused because YouTube's response format looked
  /// changed. Cached and fallback names keep working.
  final bool lookupUnavailable;

  const EmojiNamesState({
    this.names = const {},
    this.isResolving = false,
    this.lookupUnavailable = false,
  });

  EmojiNamesState copyWith({
    Map<String, ResolvedEmoji>? names,
    bool? isResolving,
    bool? lookupUnavailable,
  }) => EmojiNamesState(
    names: names ?? this.names,
    isResolving: isResolving ?? this.isResolving,
    lookupUnavailable: lookupUnavailable ?? this.lookupUnavailable,
  );
}

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`, kept on this device. Looking up the rest is
/// `EmojiNameResolver`'s.
@Riverpod(keepAlive: true)
class EmojiNames extends _$EmojiNames {
  EmojiNameCacheRepository get _cacheRepository =>
      ref.read(emojiNameCacheRepositoryProvider);
  late Future<void> _cacheLoaded;

  @override
  EmojiNamesState build() {
    ref.watch(emojiNameCacheRepositoryProvider);
    _cacheLoaded = _loadCache();
    return const EmojiNamesState();
  }

  /// Completes once the names kept on this device are in.
  Future<void> get cacheLoaded => _cacheLoaded;

  Future<void> _loadCache() async {
    final cached = await _cacheRepository.loadNames();
    if (cached.isNotEmpty) {
      state = state.copyWith(names: {...cached, ...state.names});
    }
  }

  /// Notes that names are being looked up, and whether lookups are paused.
  void setResolving({required bool resolving, bool? lookupUnavailable}) =>
      state = state.copyWith(
        isResolving: resolving,
        lookupUnavailable: lookupUnavailable,
      );

  /// Notes that lookups are paused, YouTube's responses having changed.
  void pauseLookups() => state = state.copyWith(lookupUnavailable: true);

  /// Adds looked-up names and keeps them on this device.
  Future<void> addNames(Map<String, ResolvedEmoji> found) async {
    state = state.copyWith(names: {...state.names, ...found});
    await _cacheRepository.saveNames(state.names);
  }
}

/// Resolved emoji names keyed by `emojiKey`, for search matching.
@Riverpod(keepAlive: true)
Map<String, String> emojiNamesByKey(Ref ref) {
  final names = ref.watch(emojiNamesProvider).names;
  return names.map((key, value) => MapEntry(key, value.name));
}

/// Custom emojis used in each channel's comments and live chats, most used
/// first.
@Riverpod(keepAlive: true)
Map<String, List<ChannelEmoji>> channelEmojis(Ref ref) {
  final names = ref.watch(emojiNamesByKeyProvider);

  final raws = <String, List<String>>{};
  for (final kind in QueueItemKind.values) {
    ref.watch(interactionsByChannelProvider(kind)).forEach((channelId, items) {
      raws.putIfAbsent(channelId, () => []).addAll(items.map((i) => i.rawText));
    });
  }

  final result = <String, List<ChannelEmoji>>{};
  raws.forEach((channelId, texts) {
    final counts = <String, int>{};
    final urls = <String, String>{};
    for (final raw in texts) {
      if (!raw.contains('customEmojiUrl')) continue;
      for (final segment in parseCommentSegments(raw)) {
        if (segment is! EmojiSegment) continue;
        final key = emojiKey(segment.url);
        urls.putIfAbsent(key, () => segment.url);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return;
    final emojis = [
      for (final MapEntry(:key, value: count) in counts.entries)
        ChannelEmoji(
          key: key,
          url: urls[key]!,
          name: names[key] ?? fallbackEmojiName(key),
          channelId: channelId,
          usageCount: count,
          resolved: names.containsKey(key),
        ),
    ]..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    result[channelId] = emojis;
  });
  return result;
}

/// Emoji picker sections for every channel with custom emojis, in the same
/// order as the channel list.
@riverpod
List<ChannelEmojiGroup> allChannelEmojiGroups(Ref ref) {
  final emojis = ref.watch(channelEmojisProvider);
  final channels = ref.watch(channelsProvider);
  return [
    for (final channel in channels)
      if (emojis[channel.channelId] case final list?)
        ChannelEmojiGroup(
          channelId: channel.channelId,
          channelTitle: channel.channelTitle,
          thumbnailUrl: channel.thumbnailUrl,
          emojis: list,
        ),
  ];
}

const _frequentEmojisKey = 'emoji.frequentlyUsed';
const _maxFrequentEmojis = 50;

/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.
@Riverpod(keepAlive: true)
class FrequentEmojis extends _$FrequentEmojis {
  KvStorageService get _storage => ref.read(kvStorageServiceProvider);

  @override
  Future<List<EmojiUse>> build() async {
    final storage = ref.watch(kvStorageServiceProvider);
    final raw = await storage.getString(_frequentEmojisKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?_tryDecode(item)]..sort(_byUse);
    } catch (_) {
      return const [];
    }
  }

  static EmojiUse? _tryDecode(Object? item) {
    try {
      return EmojiUseMapper.fromMap(item! as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static int _byUse(EmojiUse a, EmojiUse b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : b.lastUsed.compareTo(a.lastUsed);
  }

  Future<void> recordUse(String id) async {
    final current = await future;
    final previous = current.where((u) => u.id == id).firstOrNull;
    final uses = [
      for (final use in current)
        if (use.id != id) use,
    ];
    if (uses.length >= _maxFrequentEmojis) {
      uses.remove(
        uses.reduce((a, b) => a.lastUsed.isBefore(b.lastUsed) ? a : b),
      );
    }
    uses
      ..add(
        EmojiUse(
          id: id,
          count: (previous?.count ?? 0) + 1,
          lastUsed: DateTime.now(),
        ),
      )
      ..sort(_byUse);
    state = AsyncData(uses);
    await _storage.setString(
      _frequentEmojisKey,
      jsonEncode([for (final use in uses) use.toMap()]),
    );
  }
}

/// Emoji picker section for a single channel (empty if it has no emojis).
@riverpod
List<ChannelEmojiGroup> channelEmojiGroups(Ref ref, String channelId) {
  final emojis = ref.watch(channelEmojisProvider)[channelId];
  if (emojis == null) return const [];
  final channel = ref.watch(channelByIdProvider(channelId));
  return [
    ChannelEmojiGroup(
      channelId: channelId,
      channelTitle: channel?.channelTitle,
      thumbnailUrl: channel?.thumbnailUrl,
      emojis: emojis,
    ),
  ];
}

/// Standard emojis in each channel's comments and live chats: the ones a
/// search there would find (see [UnicodeEmojiCatalog.find]).
@Riverpod(keepAlive: true)
Map<String, Set<UnicodeEmoji>> unicodeEmojisByChannel(Ref ref) {
  final result = <String, Set<UnicodeEmoji>>{};
  void scan(String channelId, String raw) {
    if (!_hasNonAscii(raw)) return;
    for (final segment in parseCommentSegments(raw)) {
      if (segment is TextSegment) {
        _addUnicodeEmojis(
          segment.text,
          result.putIfAbsent(channelId, () => {}),
        );
      }
    }
  }

  for (final kind in QueueItemKind.values) {
    ref.watch(interactionsByChannelProvider(kind)).forEach((channelId, items) {
      for (final item in items) {
        scan(channelId, item.rawText);
      }
    });
  }
  return result;
}

/// Standard emojis in the titles of each channel's videos that have the
/// user's comments or live chats, which a channel search can match.
@Riverpod(keepAlive: true)
Map<String, Set<UnicodeEmoji>> titleUnicodeEmojisByChannel(Ref ref) {
  final videos = ref.watch(videoMetadataProvider).value ?? const {};

  final videoIds = <String, Set<String>>{};
  for (final kind in QueueItemKind.values) {
    ref.watch(interactionsByChannelProvider(kind)).forEach((channelId, items) {
      videoIds
          .putIfAbsent(channelId, () => {})
          .addAll(items.map((i) => i.videoId).nonNulls);
    });
  }

  final result = <String, Set<UnicodeEmoji>>{};
  videoIds.forEach((channelId, ids) {
    final emojis = <UnicodeEmoji>{};
    for (final id in ids) {
      final title = videos[id]?.title;
      if (title != null && _hasNonAscii(title)) {
        _addUnicodeEmojis(title, emojis);
      }
    }
    if (emojis.isNotEmpty) result[channelId] = emojis;
  });
  return result;
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

/// Standard emojis used in any comment or live chat, in picker order.
@riverpod
List<UnicodeEmoji> allUsedUnicodeEmojis(Ref ref) {
  final used = {
    for (final emojis in ref.watch(unicodeEmojisByChannelProvider).values)
      ...emojis,
  };
  return [
    for (final emoji in unicodeEmojiCatalog.all)
      if (used.contains(emoji)) emoji,
  ];
}

/// Standard emojis a search of [channelId] can find, in picker order: those
/// in its comments and live chats, and in its video titles while the search
/// matches them.
@riverpod
List<UnicodeEmoji> channelUnicodeEmojis(Ref ref, String channelId) {
  final matchTitles =
      ref.watch(searchOptionsProvider).value?.matchGroupTitles ??
      const SearchOptionsState().matchGroupTitles;
  final used = {
    ...?ref.watch(unicodeEmojisByChannelProvider)[channelId],
    if (matchTitles)
      ...?ref.watch(titleUnicodeEmojisByChannelProvider)[channelId],
  };
  if (used.isEmpty) return const [];
  return [
    for (final emoji in unicodeEmojiCatalog.all)
      if (used.contains(emoji)) emoji,
  ];
}
