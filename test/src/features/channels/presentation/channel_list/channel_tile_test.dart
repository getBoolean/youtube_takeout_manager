import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_tile.dart';

void main() {
  Future<void> pump(WidgetTester tester, Channel channel) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ChannelTile(channel: channel, onTap: () {}),
        ),
      ),
    ),
  );

  testWidgets('a channel with an empty title shows a placeholder initial', (
    tester,
  ) async {
    await pump(
      tester,
      const Channel(
        channelId: 'UC1',
        channelTitle: '',
        commentCount: 1,
        liveChatCount: 0,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets("a picture that won't load falls back to the initial", (
    tester,
  ) async {
    await pump(
      tester,
      const Channel(
        channelId: 'UC1',
        channelTitle: 'boolean',
        thumbnailUrl: 'https://yt3.example/broken',
        commentCount: 1,
        liveChatCount: 0,
      ),
    );
    // Test HTTP requests fail, so the picture never loads.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('the unknown channel shows a question mark icon', (tester) async {
    await pump(
      tester,
      const Channel(
        channelId: unknownChannelId,
        commentCount: 1,
        liveChatCount: 0,
      ),
    );

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
  });
}
