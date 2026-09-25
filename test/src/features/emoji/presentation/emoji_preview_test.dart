import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/common_widgets/search_match_marker.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// An emoji inside a tappable tile, like comment and live chat tiles.
  Future<ValueNotifier<int>> pumpTile(WidgetTester tester) async {
    final tileTaps = ValueNotifier(0);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListTile(
              onTap: () => tileTaps.value++,
              title: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'hi '),
                    WidgetSpan(
                      child: EmojiPreview(
                        url: 'https://yt3.ggpht.com/k1',
                        size: 20,
                        name: 'shortsad',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tileTaps;
  }

  final preview = find.text(':shortsad:');

  testWidgets('tapping an emoji shows its preview, not the tile action', (
    tester,
  ) async {
    final tileTaps = await pumpTile(tester);
    await tester.tap(find.byType(EmojiPreview));
    await tester.pump(const Duration(milliseconds: 100));

    expect(preview, findsOneWidget);
    expect(tileTaps.value, 0);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('right-click copies the image URL, not the tile action', (
    tester,
  ) async {
    String? copied;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final tileTaps = await pumpTile(tester);
    await tester.tap(
      find.byType(EmojiPreview),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy image URL'));
    await tester.pumpAndSettle();

    expect(copied, 'https://yt3.ggpht.com/k1');
    expect(find.text('Image URL copied'), findsOneWidget);
    expect(tileTaps.value, 0);
  });

  testWidgets('offers no URL for an emoji Takeout couldn\'t export', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmojiUrlMenu(
            url: 'Failed to get emoji URL',
            child: const ColoredBox(
              color: Colors.orange,
              child: SizedBox.square(dimension: 20),
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byType(EmojiUrlMenu),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    expect(find.text('Copy image URL'), findsNothing);
    final item = tester.widget<MenuItemButton>(
      find.widgetWithText(MenuItemButton, 'No image URL in Takeout'),
    );
    expect(item.onPressed, isNull);
  });

  testWidgets('hover shows the preview and clicking keeps it open', (
    tester,
  ) async {
    final tileTaps = await pumpTile(tester);
    final center = tester.getCenter(find.byType(EmojiPreview));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    await tester.pump(const Duration(seconds: 1));
    expect(preview, findsOneWidget);

    await mouse.down(center);
    await tester.pump();
    await mouse.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(preview, findsOneWidget);
    expect(tileTaps.value, 0);
    await mouse.removePointer();
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }, variant: TargetPlatformVariant.desktop());

  group('search match marker', () {
    Future<void> pumpEmoji(WidgetTester tester, String query) =>
        tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: EmojiPreview(
                  url: 'https://yt3.ggpht.com/k1',
                  size: 20,
                  name: 'shortsad',
                  highlightQuery: query,
                ),
              ),
            ),
          ),
        );

    final marker = find.byKey(EmojiPreview.searchMatchKey);

    testWidgets('marks an emoji whose name the query searches for', (
      tester,
    ) async {
      await pumpEmoji(tester, ':short');
      expect(marker, findsOneWidget);
    });

    testWidgets('leaves it unmarked for plain words', (tester) async {
      await pumpEmoji(tester, 'short');
      expect(marker, findsNothing);
    });

    testWidgets('joins the marker of adjacent matched emojis', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emojiNamesByKeyProvider.overrideWithValue({
              'k0': 'shortsad',
              'k2': 'other',
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EmojiPreview(
                url: 'https://yt3.ggpht.com/k1',
                size: 20,
                name: 'shortsad',
                highlightQuery: ':shortsad',
                adjacent: (
                  previousUrl: 'https://yt3.ggpht.com/k0',
                  nextUrl: 'https://yt3.ggpht.com/k2',
                ),
              ),
            ),
          ),
        ),
      );
      final shape = tester.widget<SearchMatchMarker>(marker);
      expect(shape.joinsPrevious, isTrue);
      expect(shape.joinsNext, isFalse);
    });

    testWidgets('spaces a run apart and keeps wrapped lines apart', (
      tester,
    ) async {
      String emoji(String key) =>
          '{"text":"","emoji":{"customEmojiUrl":"https://yt3.ggpht.com/$key"}}';
      final raw = [for (var i = 0; i < 9; i++) emoji('k$i')].join(',');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emojiNamesByKeyProvider.overrideWithValue({
              for (var i = 0; i < 9; i++) 'k$i': 'shortsad',
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 120,
                child: Text.rich(
                  TextSpan(
                    children: buildCommentSpans(
                      raw,
                      emojiSize: 20,
                      emojiBuilder: EmojiPreview.highlighting(':shortsad'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Rect rectOf(Element element) {
        final box = element.renderObject! as RenderBox;
        return box.localToGlobal(Offset.zero) & box.size;
      }

      final images = find.byType(EmojiImage).evaluate().map(rectOf).toList();
      final markers = marker.evaluate().map(rectOf).toList();
      final lines = {for (final rect in images) rect.top}.length;
      expect(lines, greaterThan(1));
      // Emojis in a run are a gap apart: half from each marker's padding.
      final gaps = [
        for (var i = 1; i < images.length; i++)
          if (images[i - 1].top == images[i].top)
            images[i].left - images[i - 1].right,
      ];
      expect(gaps, everyElement(greaterThan(0)));
      // Each marker also keeps half a gap clear above and below its pill, so
      // pills on consecutive lines don't touch while the markers overlap by
      // less than a gap (text layout may place them a fraction apart).
      for (final a in markers) {
        for (final b in markers) {
          if (a.top < b.top && a.bottom > b.top) {
            expect(a.bottom - b.top, lessThan(gaps.first));
          }
        }
      }
    });
  });
}
