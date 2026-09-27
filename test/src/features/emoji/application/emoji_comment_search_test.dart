import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_content_search_query.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/grouped_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_names.dart';
import 'package:youtube_takeout_manager/src/features/emoji/data/emoji_name_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_key.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/resolved_emoji.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _channel = 'UCch';
const _resolvedKey = 'resolvedKey';
const _unresolvedKey = 'unresolvedKey';

Comment _comment(String id, String raw) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime(2026),
  price: 0,
  rawCommentText: raw,
  displayText: raw,
  videoId: 'v1',
);

String _emoji(String key) =>
    '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/$key"}}';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The ids of the channel's comments a search for [query] finds, with
  /// emoji names as looked up and kept on this device.
  Future<List<String>> search(String query) async {
    await EmojiNameCacheRepository(
      KvStorageService(),
    ).saveNames({_resolvedKey: const ResolvedEmoji(name: 'shortsad')});
    final c = ProviderContainer(
      overrides: [
        interactionsByChannelProvider(QueueItemKind.comment).overrideWithValue({
          _channel: [
            _comment('resolved', '{"text":"gg "},${_emoji(_resolvedKey)}'),
            _comment('unresolved', _emoji(_unresolvedKey)),
            _comment('plain', '{"text":"so sad"}'),
          ],
        }),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(emojiNamesProvider, (_, _) {})
      ..listen(channelContentSearchQueryProvider, (_, _) {});
    await c.read(emojiNamesProvider.future);
    c.read(channelContentSearchQueryProvider.notifier).update(query);
    return [
      for (final comment in c.read(
        filteredSearchInteractionsProvider(QueueItemKind.comment, _channel),
      ))
        comment.id,
    ];
  }

  test('finds a comment by the name of its custom emoji', () async {
    expect(await search(':shortsad'), ['resolved']);
    expect(await search('gg :shortsad:'), ['resolved']);
  });

  test(
    'finds an emoji without a looked-up name by its generated name',
    () async {
      expect(await search(':${fallbackEmojiName(_unresolvedKey)}:'), [
        'unresolved',
      ]);
    },
  );

  test('plain words still match only visible text', () async {
    expect(await search('sad'), ['plain']);
  });
}
