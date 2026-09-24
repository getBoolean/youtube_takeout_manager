import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_content_search_query.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/grouped_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/video_group.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

const _channel = 'ch';
const _emojiKey = 'tigerKey';

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
  VideoGroup<LiveChat>(
    groupKey: 'v1',
    groupType: GroupType.video,
    items: [
      _chat(
        'emoji',
        '{"text":"not the reds again "},'
            '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/$_emojiKey"}}',
      ),
      _chat('text', '{"text":"he has a short"}'),
    ],
  ),
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  List<String> matchIds(String query) {
    final container = ProviderContainer(
      overrides: [
        groupedChannelLiveChatsProvider(_channel).overrideWithValue(_groups),
        emojiNamesByKeyProvider.overrideWithValue({_emojiKey: 'shortcatTiger'}),
      ],
    );
    addTearDown(container.dispose);
    container.listen(channelContentSearchQueryProvider, (_, _) {});
    container.read(channelContentSearchQueryProvider.notifier).update(query);
    return [
      for (final group in container.read(
        filteredGroupedChannelLiveChatsProvider(_channel),
      ))
        for (final chat in group.items) chat.liveChatId,
    ];
  }

  test('plain words match visible text, not emoji names', () {
    expect(matchIds('short'), ['text']);
  });

  test(':tokens match emoji names', () {
    expect(matchIds(':short'), ['emoji']);
    expect(matchIds('again :shortcat'), ['emoji']);
  });
}
