import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/presentation/live_chat_tile.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_items_dialog.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

Comment _comment(String id, {String? videoId, int day = 1}) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime.utc(2026, 1, day),
  price: 0,
  videoId: videoId,
  rawCommentText: 'text of $id',
  displayText: 'text of $id',
);

final _liveChat = LiveChat(
  liveChatId: 'chat',
  channelId: 'UCme',
  createdAt: DateTime.utc(2026, 1, 5),
  price: 0,
  videoId: 'stream',
  rawText: 'text of chat',
  displayText: 'text of chat',
);

class _Videos extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value(const {
    'saved': Video(videoId: 'saved', channelId: 'UCsaved'),
    'fetched': Video(
      videoId: 'fetched',
      channelId: 'UCelsewhere',
      channelTitle: 'Named by its video',
    ),
  });
}

late List<Uri> _opened;

Future<void> _pump(WidgetTester tester, List<Interaction> items) async {
  _opened = [];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        videoMetadataProvider.overrideWith(_Videos.new),
        channelByIdProvider('UCsaved').overrideWithValue(
          const Channel(
            channelId: 'UCsaved',
            channelTitle: 'A saved channel',
            // Never loads in tests, as a picture no longer online.
            thumbnailUrl: 'https://example.com/gone.jpg',
            commentCount: 1,
            liveChatCount: 0,
          ),
        ),
        channelByIdProvider('UCelsewhere').overrideWithValue(null),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ImportItemsDialog(
            title: 'Items',
            items: items,
            onOpen: _opened.add,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tile(String id) => find.byKey(ValueKey(('import-item', id)));

Finder _textIn(String id, String text) =>
    find.descendant(of: _tile(id), matching: find.textContaining(text));

void main() {
  testWidgets('names the channel each item is on, as far as it is known', (
    tester,
  ) async {
    await _pump(tester, [
      _comment('a', videoId: 'saved'),
      _comment('b', videoId: 'fetched'),
      _comment('c', videoId: 'unknown'),
    ]);

    expect(_textIn('a', 'A saved channel'), findsOneWidget);
    expect(_textIn('b', 'Named by its video'), findsOneWidget);
    expect(_textIn('c', 'text of c'), findsOneWidget);
  });

  testWidgets('shows the items at full strength, not faded', (tester) async {
    await _pump(tester, [_comment('a', videoId: 'saved'), _liveChat]);

    final fades = tester.widgetList<AnimatedOpacity>(
      find.descendant(
        of: find.byType(ImportItemsDialog),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(fades.map((f) => f.opacity), everyElement(1.0));
  });

  testWidgets('a long list builds only the rows in view', (tester) async {
    await _pump(tester, [
      for (var i = 0; i < 500; i++) _comment('c$i', videoId: 'saved'),
    ]);

    expect(_tile('c0'), findsOneWidget);
    expect(_tile('c499'), findsNothing);

    await tester.scrollUntilVisible(
      _tile('c60'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(_tile('c60'), findsOneWidget);
  });

  testWidgets('a live chat with no text says what it likely was, as on a '
      "channel's page", (tester) async {
    await _pump(tester, [
      LiveChat(
        liveChatId: 'empty',
        channelId: 'UCme',
        createdAt: DateTime.utc(2026),
        price: 0,
        videoId: 'stream',
        rawText: '',
        displayText: '',
      ),
    ]);

    expect(
      find.descendant(
        of: _tile('empty'),
        matching: find.text(emptyLiveChatLabel),
      ),
      findsOneWidget,
    );
  });

  testWidgets('lists the items in the order given', (tester) async {
    await _pump(tester, [
      _comment('a', videoId: 'saved', day: 3),
      _comment('b', videoId: 'fetched', day: 2),
    ]);

    expect(
      tester.getTopLeft(_tile('a')).dy,
      lessThan(tester.getTopLeft(_tile('b')).dy),
    );
  });

  testWidgets('opens a comment on YouTube scrolled to itself', (tester) async {
    await _pump(tester, [_comment('a', videoId: 'saved')]);

    await tester.tap(_tile('a'));

    expect(_opened.single.queryParameters, {'v': 'saved', 'lc': 'a'});
  });

  testWidgets('a live chat opens its video', (tester) async {
    await _pump(tester, [_liveChat]);

    await tester.tap(_tile('chat'));

    expect(_opened.single.queryParameters, {'v': 'stream'});
  });
}
