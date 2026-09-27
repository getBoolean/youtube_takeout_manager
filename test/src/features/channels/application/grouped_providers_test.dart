import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_content_search_query.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/grouped_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/search_options_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_options_state.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/video_group.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_names.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

const _channel = 'ch';
const _emojiKey = 'tigerKey';
const _heart = '❤';
const _heartEmoji = '❤️';

LiveChat _chat(String id, String raw) => LiveChat(
  liveChatId: id,
  channelId: _channel,
  createdAt: DateTime(2024),
  price: 0,
  videoId: 'v1',
  rawText: raw,
  displayText: raw,
);

final _groups = [
  VideoGroup<LiveChat>.video('v1', [
    _chat(
      'emoji',
      '{"text":"not the reds again "},'
          '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/$_emojiKey"}}',
    ),
    _chat('text', '{"text":"he has a short"}'),
    _chat('heart', '{"text":"love it $_heart"}'),
    _chat('heart-emoji', '{"text":"love it $_heartEmoji"}'),
  ]),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  List<String> matchIds(String query) {
    final container = ProviderContainer(
      overrides: [
        groupedChannelInteractionsProvider(
          QueueItemKind.liveChat,
          _channel,
        ).overrideWithValue(_groups),
        emojiNamesByKeyProvider.overrideWithValue({_emojiKey: 'shortcatTiger'}),
      ],
    );
    addTearDown(container.dispose);
    container.listen(channelContentSearchQueryProvider, (_, _) {});
    container.read(channelContentSearchQueryProvider.notifier).update(query);
    return [
      for (final group in container.read(
        filteredGroupedChannelInteractionsProvider(
          QueueItemKind.liveChat,
          _channel,
        ),
      ))
        for (final chat in group.items) chat.id,
    ];
  }

  test('plain words match visible text, not emoji names', () {
    expect(matchIds('short'), ['text']);
  });

  test(':tokens match emoji names', () {
    expect(matchIds(':short'), ['emoji']);
    expect(matchIds('again :shortcat'), ['emoji']);
  });

  test('❤️ and ❤ match each other', () {
    expect(matchIds(_heartEmoji), ['heart', 'heart-emoji']);
    expect(matchIds(_heart), ['heart', 'heart-emoji']);
  });

  _searchTests();
}

Comment _comment(String id, String videoId, String text) => Comment(
  commentId: id,
  channelId: _channel,
  createdAt: DateTime(2024),
  price: 0,
  videoId: videoId,
  rawCommentText: '{"text":"$text"}',
  displayText: text,
);

final _cooking = VideoGroup<Comment>.video('cooking', [
  _comment('salt', 'cooking', 'needs salt'),
  _comment('pepper', 'cooking', 'and pepper'),
]);
final _travel = VideoGroup<Comment>.video('travel', [
  _comment('salt-again', 'travel', 'salt water'),
  _comment('beach', 'travel', 'nice beach'),
]);

class _Videos extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value(const {
    'cooking': Video(videoId: 'cooking', channelId: _channel, title: 'Soup'),
    'travel': Video(videoId: 'travel', channelId: _channel, title: 'Coast'),
  });
}

class _Options extends SearchOptions {
  final SearchOptionsState options;

  _Options(this.options);

  @override
  Future<SearchOptionsState> build() async => options;
}

class _Deleted extends DeletedIds {
  @override
  Future<Map<QueueItemKind, Set<String>>> build() async => {
    QueueItemKind.comment: {'salt'},
  };
}

void _searchTests() {
  Future<ProviderContainer> search(
    String query, {
    SearchOptionsState options = const SearchOptionsState(),
  }) async {
    final c = ProviderContainer(
      overrides: [
        groupedChannelInteractionsProvider(
          QueueItemKind.comment,
          _channel,
        ).overrideWithValue([_cooking, _travel]),
        videoMetadataProvider.overrideWith(_Videos.new),
        searchOptionsProvider.overrideWith(() => _Options(options)),
        deletedIdsProvider.overrideWith(_Deleted.new),
        emojiNamesByKeyProvider.overrideWithValue(const {}),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(channelContentSearchQueryProvider, (_, _) {})
      ..listen(videoMetadataProvider, (_, _) {})
      ..listen(searchOptionsProvider, (_, _) {})
      ..listen(deletedIdsProvider, (_, _) {});
    await c.read(videoMetadataProvider.future);
    await c.read(searchOptionsProvider.future);
    await c.read(deletedIdsProvider.future);
    c.read(channelContentSearchQueryProvider.notifier).update(query);
    return c;
  }

  Map<String?, List<String>> groups(ProviderContainer c) => {
    for (final g in c.read(
      filteredGroupedChannelInteractionsProvider(
        QueueItemKind.comment,
        _channel,
      ),
    ))
      g.videoId: [for (final i in g.items) i.id],
  };

  group('channel search', () {
    test('a video title match brings its whole group', () async {
      final c = await search(
        'SOUP',
        options: const SearchOptionsState(matchGroupTitles: true),
      );
      expect(groups(c), {
        'cooking': ['salt', 'pepper'],
      });
    });

    test("without matching titles, a title alone doesn't match", () async {
      final c = await search(
        'soup',
        options: const SearchOptionsState(matchGroupTitles: false),
      );
      expect(groups(c), isEmpty);
    });

    test('shows only the matching items of a video', () async {
      final c = await search(
        'salt',
        options: const SearchOptionsState(expandMatchedVideos: false),
      );
      expect(groups(c), {
        'cooking': ['salt'],
        'travel': ['salt-again'],
      });
    });

    test('can show every item of a video with a match', () async {
      final c = await search(
        'salt',
        options: const SearchOptionsState(expandMatchedVideos: true),
      );
      expect(groups(c), {
        'cooking': ['salt', 'pepper'],
        'travel': ['salt-again', 'beach'],
      });
    });

    test('the results to act on leave out deleted items', () async {
      final c = await search('salt');
      expect(
        [
          for (final i in c.read(
            filteredSearchInteractionsProvider(QueueItemKind.comment, _channel),
          ))
            i.id,
        ],
        ['salt-again'],
      );
    });

    test('there are no results to act on without a query', () async {
      final c = await search('');
      expect(
        c.read(
          filteredSearchInteractionsProvider(QueueItemKind.comment, _channel),
        ),
        isEmpty,
      );
    });
  });
}
