import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/app_effects.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_channel_assignment.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_name_resolver.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_names.dart';
import 'package:youtube_takeout_manager/src/features/emoji/data/youtube_emoji_name_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_lookup.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/resolved_emoji.dart';
import 'package:youtube_takeout_manager/src/features/history/application/watched_video_format_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/legacy_takeout_migration.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';

class _Thumbnails extends ChannelThumbnailFetcher {
  final List<String> started;

  _Thumbnails(this.started);

  @override
  void build() => started.add('thumbnails');
}

class _EmojiNames extends EmojiNameResolver {
  final List<String> started;

  _EmojiNames(this.started);

  @override
  void build() => started.add('emoji names');
}

class _Lookups extends YoutubeEmojiNameRepository {
  final videos = <String>[];

  @override
  Future<EmojiLookupResult> resolveFromVideo(
    String videoId,
    List<DateTime> messageTimes, {
    required Set<String> wantedKeys,
    int maxRequests = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    videos.add(videoId);
    return EmojiLookupResult(EmojiLookupStatus.ok, {
      for (final key in wantedKeys) key: const ResolvedEmoji(name: 'wave'),
    });
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the app starts every effect', () async {
    final started = <String>[];
    final c = ProviderContainer(
      overrides: [
        legacySignInMigrationProvider.overrideWith(
          (ref) async => started.add('legacy sign-in'),
        ),
        legacyTakeoutMigrationProvider.overrideWith(
          (ref) async => started.add('legacy takeouts'),
        ),
        channelThumbnailFetcherProvider.overrideWith(
          () => _Thumbnails(started),
        ),
        videoTitleFetcherProvider.overrideWith(
          (ref) => Stream.value(started.add('video titles')),
        ),
        watchedVideoFormatFetcherProvider.overrideWith(
          (ref) => Stream.value(started.add('video formats')),
        ),
        emojiNameResolverProvider.overrideWith(() => _EmojiNames(started)),
        queueChannelAssignmentProvider.overrideWith(
          (ref) => started.add('queue channels'),
        ),
      ],
    );
    addTearDown(c.dispose);

    c.listen(appEffectsProvider, (_, _) {});
    await pumpEventQueue();

    expect(started, {
      'legacy sign-in',
      'legacy takeouts',
      'thumbnails',
      'video titles',
      'video formats',
      'emoji names',
      'queue channels',
    });
  });

  test('looks up custom emoji names once live chats load', () async {
    final lookups = _Lookups();
    final c = ProviderContainer(
      overrides: [
        youtubeEmojiNameRepositoryProvider.overrideWithValue(lookups),
        allInteractionsProvider(QueueItemKind.liveChat).overrideWithValue([
          LiveChat(
            liveChatId: 'l1',
            channelId: 'UCme',
            createdAt: DateTime.utc(2026),
            price: 0,
            videoId: 'v1',
            rawText:
                '{"text":"","emoji":{"customEmojiUrl":'
                '"https://yt3.ggpht.com/wave-key"}}',
            displayText: '',
          ),
        ]),
      ],
    );
    addTearDown(c.dispose);

    c.listen(emojiNameResolverProvider, (_, _) {});
    for (var i = 0; i < 10; i++) {
      await pumpEventQueue();
    }

    expect(lookups.videos, ['v1']);
    expect(
      c.read(emojiNamesProvider).requireValue.names.values.map((e) => e.name),
      ['wave'],
    );
    expect(c.read(emojiNamesProvider).requireValue.isResolving, isFalse);
  });
}
