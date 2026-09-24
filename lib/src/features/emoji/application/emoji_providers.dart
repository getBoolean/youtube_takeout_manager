import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../data/emoji_name_cache_service.dart';
import '../data/youtube_emoji_name_service.dart';
import '../domain/channel_emoji.dart';

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

const _retryFailedAfter = Duration(days: 7);
const _pauseAfterFormatChange = Duration(days: 3);

/// Consecutive failures of one kind before the current run is abandoned.
const _maxConsecutiveFailures = 2;

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`. Loaded from cache on start; [resolveMissing] looks up the rest.
@Riverpod(keepAlive: true)
class EmojiNames extends _$EmojiNames {
  final _cacheService = EmojiNameCacheService();
  late Future<void> _cacheLoaded;

  @override
  EmojiNamesState build() {
    _cacheLoaded = _loadCache();
    return const EmojiNamesState();
  }

  Future<void> _loadCache() async {
    final cached = await _cacheService.loadNames();
    if (cached.isNotEmpty) {
      state = state.copyWith(names: {...cached, ...state.names});
    }
  }

  /// Scans the user's live chats for emojis without a known name and reads
  /// the replay of each video they were sent in. Native platforms only.
  ///
  /// Never throws. Backs off when YouTube is unreachable, and pauses lookups
  /// for [_pauseAfterFormatChange] when its responses stop parsing.
  Future<void> resolveMissing() async {
    if (kIsWeb || state.isResolving) return;
    try {
      await _resolveMissing();
    } catch (e) {
      debugPrint('Emoji name resolution failed: $e');
    } finally {
      if (ref.mounted) state = state.copyWith(isResolving: false);
    }
  }

  Future<void> _resolveMissing() async {
    await _cacheLoaded;
    final pausedUntil = await _cacheService.loadPausedUntil();
    if (pausedUntil != null && DateTime.now().isBefore(pausedUntil)) {
      state = state.copyWith(lookupUnavailable: true);
      return;
    }

    final keysByVideo = <String, Set<String>>{};
    final timesByVideo = <String, List<DateTime>>{};
    for (final chat in ref.read(allLiveChatsProvider)) {
      final videoId = chat.videoId;
      if (videoId == null) continue;
      for (final segment in parseCommentSegments(chat.rawText)) {
        if (segment is! EmojiSegment) continue;
        final key = emojiKey(segment.url);
        if (state.names.containsKey(key)) continue;
        keysByVideo.putIfAbsent(videoId, () => {}).add(key);
        timesByVideo.putIfAbsent(videoId, () => []).add(chat.createdAt);
      }
    }
    if (keysByVideo.isEmpty) return;

    final attempts = await _cacheService.loadAttempts();
    final now = DateTime.now();
    keysByVideo.removeWhere((videoId, _) {
      final last = attempts[videoId];
      return last != null && now.difference(last) < _retryFailedAfter;
    });
    if (keysByVideo.isEmpty) return;

    state = state.copyWith(isResolving: true, lookupUnavailable: false);
    final service = YoutubeEmojiNameService();
    try {
      var first = true;
      var networkFailures = 0;
      var formatFailures = 0;
      for (final MapEntry(key: videoId, value: keys) in keysByVideo.entries) {
        final wanted = keys.difference(state.names.keys.toSet());
        if (wanted.isEmpty) continue;
        if (!first) await Future<void>.delayed(const Duration(seconds: 1));
        first = false;

        final result = await service.resolveFromVideo(
          videoId,
          timesByVideo[videoId]!,
          wantedKeys: wanted,
        );
        if (!ref.mounted) return;
        if (result.found.isNotEmpty) {
          state = state.copyWith(names: {...state.names, ...result.found});
          await _cacheService.saveNames(state.names);
        }

        switch (result.status) {
          case EmojiLookupStatus.ok || EmojiLookupStatus.noReplay:
            networkFailures = 0;
            formatFailures = 0;
            attempts[videoId] = DateTime.now();
            await _cacheService.saveAttempts(attempts);
          case EmojiLookupStatus.networkError:
            // Probably offline or rate limited; try again next launch.
            if (++networkFailures >= _maxConsecutiveFailures) return;
          case EmojiLookupStatus.unexpectedFormat:
            // Not recorded as attempted so the video is retried once the
            // pause ends (e.g. after an app update adapts to the change).
            if (++formatFailures >= _maxConsecutiveFailures) {
              await _cacheService.savePausedUntil(
                DateTime.now().add(_pauseAfterFormatChange),
              );
              state = state.copyWith(lookupUnavailable: true);
              return;
            }
        }
      }
    } finally {
      service.close();
    }
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
  final commentsByChannel = ref.watch(commentsByChannelProvider);
  final liveChatsByChannel = ref.watch(liveChatsByChannelProvider);
  final names = ref.watch(emojiNamesByKeyProvider);

  final raws = <String, List<String>>{};
  commentsByChannel.forEach((channelId, comments) {
    raws
        .putIfAbsent(channelId, () => [])
        .addAll(comments.map((c) => c.rawCommentText));
  });
  liveChatsByChannel.forEach((channelId, chats) {
    raws.putIfAbsent(channelId, () => []).addAll(chats.map((c) => c.rawText));
  });

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
