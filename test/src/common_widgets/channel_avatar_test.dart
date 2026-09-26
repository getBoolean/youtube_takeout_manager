import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets("shows the channel's picture", (tester) async {
    await pump(
      tester,
      const ChannelAvatar(
        name: 'Boolean',
        thumbnailUrl: 'https://yt3.example/boolean',
        radius: 20,
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://yt3.example/boolean');
  });

  testWidgets('without a picture, shows the initial', (tester) async {
    await pump(tester, const ChannelAvatar(name: 'boolean', radius: 20));

    expect(find.byType(Image), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('a channel identity shows its picture beside its name', (
    tester,
  ) async {
    await pump(
      tester,
      const ChannelIdentity(
        channelId: 'UCme',
        title: 'Boolean',
        thumbnailUrl: 'https://yt3.example/boolean',
      ),
    );

    expect(find.byType(ChannelAvatar), findsOneWidget);
    expect(find.text('Boolean'), findsOneWidget);
  });
}
