import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../data/emoji_name_cache_repository.dart';
import '../data/youtube_emoji_name_repository.dart';
import 'emoji_providers.dart';

part 'emoji_name_resolver.g.dart';

const _retryFailedAfter = Duration(days: 7);
const _pauseAfterFormatChange = Duration(days: 3);

/// Consecutive failures of one kind before the current run is abandoned.
const _maxConsecutiveFailures = 2;

/// Looks up names for the custom emojis in the viewed channel's live chats
/// once they're loaded. An effect: nothing depends on it, so it can read
/// any provider.
@Riverpod(keepAlive: true)
class EmojiNameResolver extends _$EmojiNameResolver {
  EmojiNameCacheRepository get _cacheRepository =>
      ref.read(emojiNameCacheRepositoryProvider);

  @override
  void build() {
    ref.listen(allLiveChatsProvider, (_, liveChats) {
      if (liveChats.isNotEmpty) resolveMissing();
    }, fireImmediately: true);
  }

  /// Scans the user's live chats for emojis without a known name and reads
  /// the replay of each video they were sent in. Native platforms only.
  ///
  /// Never throws. Backs off when YouTube is unreachable, and pauses lookups
  /// for [_pauseAfterFormatChange] when its responses stop parsing.
  Future<void> resolveMissing() async {
    if (kIsWeb || ref.read(emojiNamesProvider).isResolving) return;
    final names = ref.read(emojiNamesProvider.notifier);
    try {
      await _resolveMissing(names);
    } catch (e) {
      debugPrint('Emoji name resolution failed: $e');
    } finally {
      if (ref.mounted) names.setResolving(resolving: false);
    }
  }

  Future<void> _resolveMissing(EmojiNames names) async {
    await names.cacheLoaded;
    final pausedUntil = await _cacheRepository.loadPausedUntil();
    if (pausedUntil != null && DateTime.now().isBefore(pausedUntil)) {
      names.pauseLookups();
      return;
    }

    final known = ref.read(emojiNamesProvider).names;
    final keysByVideo = <String, Set<String>>{};
    final timesByVideo = <String, List<DateTime>>{};
    for (final chat in ref.read(allLiveChatsProvider)) {
      final videoId = chat.videoId;
      if (videoId == null) continue;
      for (final segment in parseCommentSegments(chat.rawText)) {
        if (segment is! EmojiSegment) continue;
        final key = emojiKey(segment.url);
        if (known.containsKey(key)) continue;
        keysByVideo.putIfAbsent(videoId, () => {}).add(key);
        timesByVideo.putIfAbsent(videoId, () => []).add(chat.createdAt);
      }
    }
    if (keysByVideo.isEmpty) return;

    final attempts = await _cacheRepository.loadAttempts();
    final now = DateTime.now();
    keysByVideo.removeWhere((videoId, _) {
      final last = attempts[videoId];
      return last != null && now.difference(last) < _retryFailedAfter;
    });
    if (keysByVideo.isEmpty) return;

    names.setResolving(resolving: true, lookupUnavailable: false);
    final lookupRepository = ref.read(youtubeEmojiNameRepositoryProvider);
    var first = true;
    var networkFailures = 0;
    var formatFailures = 0;
    for (final MapEntry(key: videoId, value: keys) in keysByVideo.entries) {
      final wanted = keys.difference(
        ref.read(emojiNamesProvider).names.keys.toSet(),
      );
      if (wanted.isEmpty) continue;
      if (!first) await Future<void>.delayed(const Duration(seconds: 1));
      first = false;

      final result = await lookupRepository.resolveFromVideo(
        videoId,
        timesByVideo[videoId]!,
        wantedKeys: wanted,
      );
      if (!ref.mounted) return;
      if (result.found.isNotEmpty) await names.addNames(result.found);

      switch (result.status) {
        case EmojiLookupStatus.ok || EmojiLookupStatus.noReplay:
          networkFailures = 0;
          formatFailures = 0;
          attempts[videoId] = DateTime.now();
          await _cacheRepository.saveAttempts(attempts);
        case EmojiLookupStatus.networkError:
          // Probably offline or rate limited; try again next launch.
          if (++networkFailures >= _maxConsecutiveFailures) return;
        case EmojiLookupStatus.unexpectedFormat:
          // Not recorded as attempted so the video is retried once the
          // pause ends (e.g. after an app update adapts to the change).
          if (++formatFailures >= _maxConsecutiveFailures) {
            await _cacheRepository.savePausedUntil(
              DateTime.now().add(_pauseAfterFormatChange),
            );
            names.pauseLookups();
            return;
          }
      }
    }
  }
}
