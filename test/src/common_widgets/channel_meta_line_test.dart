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

  testWidgets("a channel's picture that won't load keeps its space, so the "
      'name stays put', (tester) async {
    await pump(
      tester,
      const ChannelMetaLine(
        channelName: 'Shortcat',
        thumbnailUrl: 'https://yt3.example/broken',
        detail: '2:05 PM',
      ),
    );
    final before = nameStart(tester);

    // Test HTTP requests fail, so the picture never loads.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(nameStart(tester), before);
  });

  testWidgets(
    "with its space kept, a channel's picture arriving moves "
    'nothing, however wide the line',
    expectPictureArrivesInPlace,
  );

  testWidgets('with larger text, the detail is still never cut off beside '
      "the channel's picture", (tester) async {
    // Past where the line fits once, with square test glyphs.
    for (var width = 380.0; width <= 460; width += 2) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: const ChannelMetaLine(
                    channelName: 'Shortcat Gaming',
                    keepPictureSpace: true,
                    detail: '2:05 PM',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final withDetail = find.textContaining('2:05 PM', findRichText: true);
      expect(
        tester.renderObject<RenderParagraph>(withDetail).didExceedMaxLines,
        isFalse,
        reason: '$width',
      );
    }
  });
}

/// Checks, across widths, that the line keeps its size and its name keeps
/// its place when the channel's picture arrives, as it does when its space
/// is kept for it.
Future<void> expectPictureArrivesInPlace(WidgetTester tester) async {
  for (var width = 100.0; width <= 260; width += 4) {
    Widget line(String? url) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ChannelMetaLine(
              channelName: 'Shortcat Gaming',
              thumbnailUrl: url,
              keepPictureSpace: true,
              detail: '2:05 PM',
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(line(null));
    final size = tester.getSize(find.byType(ChannelMetaLine));
    final start = nameStart(tester, 'Shortcat');

    await tester.pumpWidget(line('https://yt3.example/shortcat'));

    expect(
      tester.getSize(find.byType(ChannelMetaLine)),
      size,
      reason: '$width',
    );
    expect(nameStart(tester, 'Shortcat'), start, reason: '$width');
  }
}

/// Where the channel's name starts, after its picture.
double nameStart(WidgetTester tester, [String name = 'Shortcat']) => tester
    .renderObject<RenderParagraph>(
      find.textContaining(name, findRichText: true).first,
    )
    .getOffsetForCaret(const TextPosition(offset: 1), Rect.zero)
    .dx;
