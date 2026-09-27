import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/video_thumbnail.dart';

void main() {
  Future<void> pump(WidgetTester tester, String? url) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: 160,
          height: 90,
          child: VideoThumbnail(
            url: url,
            placeholderIcon: Icons.videocam_outlined,
          ),
        ),
      ),
    ),
  );

  testWidgets('a video without a thumbnail shows the placeholder', (
    tester,
  ) async {
    await pump(tester, null);

    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
  });

  testWidgets("a thumbnail that won't load shows the placeholder", (
    tester,
  ) async {
    await pump(tester, 'https://i.ytimg.com/vi/broken/mqdefault.jpg');
    expect(find.byIcon(Icons.videocam_outlined), findsNothing);

    // Test HTTP requests fail, so the picture never loads.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
  });
}
