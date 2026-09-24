import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';

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
  });
}
