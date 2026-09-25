import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_app_bar.dart';

void main() {
  Future<void> pumpTitle(WidgetTester tester, {double width = 800}) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const ChannelTitle(
              channelName: 'Ada',
              channelUrl: 'https://www.youtube.com/channel/UCada',
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('clicking the name asks before opening YouTube', (tester) async {
    await pumpTitle(tester);

    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    expect(find.text('Open Ada on YouTube?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Open Ada on YouTube?'), findsNothing);
  });

  testWidgets('the globe beside the name asks too', (tester) async {
    await pumpTitle(tester);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    expect(find.text('Open Ada on YouTube?'), findsOneWidget);
  });

  testWidgets('leaves the globe out when narrow', (tester) async {
    await pumpTitle(tester, width: 200);

    expect(find.byIcon(Icons.language), findsNothing);
    expect(find.text('Ada'), findsOneWidget);
  });
}
