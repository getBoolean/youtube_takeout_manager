import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_meta_line.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget line, {double width = 400}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: line),
            ),
          ),
        ),
      );

  testWidgets('names the channel and the detail', (tester) async {
    await pump(
      tester,
      const ChannelMetaLine(channelName: 'Shortcat', detail: '2:05 PM'),
    );

    expect(
      find.textContaining('Shortcat · 2:05 PM', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('without a channel shows only the detail', (tester) async {
    await pump(tester, const ChannelMetaLine(detail: '2:05 PM'));

    expect(find.text('2:05 PM', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'keeps the detail whole, on its own line, when both would not fit',
    (tester) async {
      const detail = 'Apr 12, 2026 2:05 PM';
      await pump(
        tester,
        const ChannelMetaLine(
          prefix: 'on ',
          channelName: 'A channel with a very long name indeed',
          detail: detail,
        ),
        width: 160,
      );

      expect(tester.takeException(), isNull);
      final shown = find.text(detail);
      expect(shown, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(shown).didExceedMaxLines,
        isFalse,
      );
      expect(tester.getSize(shown).width, lessThanOrEqualTo(160));
    },
  );
}
