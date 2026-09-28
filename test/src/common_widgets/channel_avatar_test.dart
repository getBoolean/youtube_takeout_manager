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

    final image = tester.widget<Image>(find.byType(Image)).image;
    final network = image is ResizeImage ? image.imageProvider : image;
    expect((network as NetworkImage).url, 'https://yt3.example/boolean');
  });

  testWidgets("shows the channel's initial while its picture loads", (
    tester,
  ) async {
    await pump(
      tester,
      const ChannelAvatar(
        name: 'boolean',
        thumbnailUrl: 'https://yt3.example/boolean',
        radius: 20,
      ),
    );

    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('decodes its picture no bigger than it is shown', (tester) async {
    await pump(
      tester,
      const ChannelAvatar(
        name: 'Boolean',
        thumbnailUrl: 'https://yt3.example/boolean',
        radius: 20,
      ),
    );

    final image = tester.widget<Image>(find.byType(Image)).image;
    expect(image, isA<ResizeImage>());
    expect(
      (image as ResizeImage).width,
      (40 * tester.view.devicePixelRatio).ceil(),
    );
  });

  testWidgets('without a picture, shows the initial', (tester) async {
    await pump(tester, const ChannelAvatar(name: 'boolean', radius: 20));

    expect(find.byType(Image), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('an icon stands in for a channel that isn\'t known', (
    tester,
  ) async {
    await pump(
      tester,
      const ChannelAvatar(name: '', icon: Icons.help_outline, radius: 20),
    );

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.text('?'), findsNothing);
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
