import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_name_resolver.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_names.dart';
import 'package:youtube_takeout_manager/src/features/emoji/data/emoji_name_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/data/youtube_emoji_name_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_lookup.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/resolved_emoji.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

/// A live chat on [videoId] with a custom emoji of its own.
LiveChat _chat(String videoId) => LiveChat(
  liveChatId: 'chat-$videoId',
  channelId: 'UCme',
  createdAt: DateTime.utc(2026),
  price: 0,
  videoId: videoId,
  rawText:
      '{"text":"","emoji":{"customEmojiUrl":'
      '"https://yt3.ggpht.com/key-$videoId"}}',
  displayText: '',
);

/// Answers every lookup with [status], finding every wanted emoji when ok.
class _Lookups extends YoutubeEmojiNameRepository {
  final EmojiLookupStatus status;
  final videos = <String>[];

  _Lookups(this.status);

  @override
  Future<EmojiLookupResult> resolveFromVideo(
    String videoId,
    List<DateTime> messageTimes, {
    required Set<String> wantedKeys,
    int maxRequests = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    videos.add(videoId);
    return EmojiLookupResult(status, {
      if (status == EmojiLookupStatus.ok)
        for (final key in wantedKeys) key: const ResolvedEmoji(name: 'wave'),
    });
  }
}

EmojiNameCacheRepository _cache() =>
    EmojiNameCacheRepository(KvStorageService());

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Starts the resolver, as the app does on launch, for chats on [videos],
  /// and waits for it to finish. [looksUp] says whether it's expected to
  /// look anything up.
  Future<ProviderContainer> launch(
    _Lookups lookups,
    List<String> videos, {
    bool looksUp = true,
  }) async {
    final c = ProviderContainer(
      overrides: [
        youtubeEmojiNameRepositoryProvider.overrideWithValue(lookups),
        allInteractionsProvider(
          QueueItemKind.liveChat,
        ).overrideWithValue([for (final video in videos) _chat(video)]),
      ],
    );
    addTearDown(c.dispose);
    final done = Completer<void>();
    var resolving = false;
    c.listen(emojiNamesProvider, (_, next) {
      final now = next.value?.isResolving ?? false;
      if (resolving && !now && !done.isCompleted) done.complete();
      resolving = now;
    });
    c.listen(emojiNameResolverProvider, (_, _) {});
    if (looksUp) {
      await done.future.timeout(const Duration(seconds: 30));
    } else {
      await pumpEventQueue(times: 100);
    }
    return c;
  }

  bool paused(ProviderContainer c) =>
      c.read(emojiNamesProvider).requireValue.lookupUnavailable;

  test('looks up names and remembers which videos it read', () async {
    final lookups = _Lookups(EmojiLookupStatus.ok);
    final c = await launch(lookups, ['v1']);

    expect(lookups.videos, ['v1']);
    expect(c.read(emojiNamesByKeyProvider), {'key-v1': 'wave'});
    expect((await _cache().loadAttempts()).keys, ['v1']);
  });

  test('pauses lookups when YouTube keeps answering in an unexpected format, '
      'also on the next launch', () async {
    final videos = [for (var i = 0; i < 10; i++) 'v$i'];
    final lookups = _Lookups(EmojiLookupStatus.unexpectedFormat);
    final c = await launch(lookups, videos);

    expect(lookups.videos.length, lessThan(videos.length));
    expect(paused(c), isTrue);
    expect(await _cache().loadPausedUntil(), isNotNull);
    expect((await _cache().loadPausedUntil())!.isAfter(DateTime.now()), isTrue);
    // Not counted as read, so they're retried once the pause ends.
    expect(await _cache().loadAttempts(), isEmpty);

    final nextLaunch = _Lookups(EmojiLookupStatus.ok);
    final next = await launch(nextLaunch, videos, looksUp: false);
    expect(nextLaunch.videos, isEmpty);
    expect(paused(next), isTrue);
  });

  test('looks up again once a pause has ended', () async {
    await _cache().savePausedUntil(
      DateTime.now().subtract(const Duration(minutes: 1)),
    );
    final lookups = _Lookups(EmojiLookupStatus.ok);
    final c = await launch(lookups, ['v1']);

    expect(lookups.videos, ['v1']);
    expect(paused(c), isFalse);
  });

  test('skips videos read recently, and reads them again much later', () async {
    final now = DateTime.now();
    await _cache().saveAttempts({
      'recent': now.subtract(const Duration(hours: 1)),
      'old': now.subtract(const Duration(days: 365)),
    });
    final lookups = _Lookups(EmojiLookupStatus.ok);
    await launch(lookups, ['recent', 'old']);

    expect(lookups.videos, ['old']);
  });

  test('gives up for now when YouTube keeps being unreachable, and tries '
      'again next launch', () async {
    final videos = [for (var i = 0; i < 10; i++) 'v$i'];
    final lookups = _Lookups(EmojiLookupStatus.networkError);
    final c = await launch(lookups, videos);

    expect(lookups.videos.length, lessThan(videos.length));
    expect(paused(c), isFalse);
    expect(await _cache().loadAttempts(), isEmpty);
    expect(await _cache().loadPausedUntil(), isNull);

    final nextLaunch = _Lookups(EmojiLookupStatus.ok);
    await launch(nextLaunch, videos.take(1).toList());
    expect(nextLaunch.videos, ['v0']);
  });
}
