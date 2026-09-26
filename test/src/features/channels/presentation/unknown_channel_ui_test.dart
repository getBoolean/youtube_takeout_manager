import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_app_bar.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/channel_tile.dart';

const _unknown = Channel(
  channelId: unknownChannelId,
  channelTitle: 'Unknown channel',
  commentCount: 3,
  liveChatCount: 1,
);

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );

  testWidgets('the unknown tile explains why when signed out', (tester) async {
    await pump(tester, ChannelTile(channel: _unknown, onTap: () {}));

    expect(find.text('Unknown channel'), findsOneWidget);
    expect(find.text('Sign in to sort these by channel'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    // No initial standing in for an avatar it doesn't have.
    expect(find.text('U'), findsNothing);
  });

  testWidgets('a title without a channel page opens nothing', (tester) async {
    await pump(
      tester,
      const ChannelTitle(channelName: 'Unknown channel', channelUrl: null),
    );

    expect(find.byIcon(Icons.language), findsNothing);
    expect(find.byTooltip('Open on YouTube…'), findsNothing);
    await tester.tap(find.text('Unknown channel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
