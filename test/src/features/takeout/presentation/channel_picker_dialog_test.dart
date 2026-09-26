import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/channel_picker_dialog.dart';

const _channels = [
  TakeoutChannel(
    channelId: 'UCmain',
    title: 'Boolean',
    isMain: true,
    listed: true,
    commentCount: 1234,
    liveChatCount: 5,
  ),
  TakeoutChannel(
    channelId: 'UCalt',
    isMain: false,
    listed: false,
    commentCount: 1,
  ),
];

void main() {
  Future<String?> pick(WidgetTester tester, {String? tap}) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<String>(
              context: context,
              builder: (_) => const ChannelPickerDialog(
                channels: _channels,
                viewedChannelId: 'UCalt',
                signedInChannelIds: {'UCmain'},
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    if (tap != null) {
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
    }
    return result;
  }

  testWidgets('lists each channel with what it has', (tester) async {
    await pick(tester);

    expect(find.text('Boolean'), findsOneWidget);
    expect(find.textContaining('1,234 comments · 5 live chats'), findsOne);
    expect(find.textContaining('Signed in'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Viewing'), findsOneWidget);
    // A channel without a title shows its ID.
    expect(find.text('UCalt'), findsOneWidget);
  });

  testWidgets('returns the channel picked', (tester) async {
    expect(await pick(tester, tap: 'Boolean'), 'UCmain');
  });
}
