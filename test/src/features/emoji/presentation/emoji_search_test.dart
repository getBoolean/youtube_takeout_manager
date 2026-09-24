import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/channel_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/debounced_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_text_editing_controller.dart';

const _shortsad = ChannelEmoji(
  key: 'k1',
  url: 'https://yt3.ggpht.com/k1',
  name: 'shortsad',
  channelId: 'UC1',
  usageCount: 3,
  resolved: true,
);
const _shypraise = ChannelEmoji(
  key: 'k2',
  url: 'https://yt3.ggpht.com/k2',
  name: 'shypraise',
  channelId: 'UC1',
  usageCount: 1,
  resolved: true,
);

EmojiTextEditingController _controller(String text) =>
    EmojiTextEditingController()
      ..emojisByName = {'shortsad': _shortsad}
      ..value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('EmojiTextEditingController', () {
    testWidgets('span length matches text length', (tester) async {
      final controller = _controller('hi :shortsad: :unknown: x');
      late TextSpan span;
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(span.toPlainText().length, controller.text.length);
      expect(span.toPlainText(), contains('￼'));
      expect(span.toPlainText(), contains(':unknown:'));
    });

    test('backspace at a token end removes the whole token', () {
      final controller = _controller('a :shortsad:');
      controller.value = const TextEditingValue(
        text: 'a :shortsad',
        selection: TextSelection.collapsed(offset: 11),
      );
      expect(controller.text, 'a ');
      expect(controller.selection.baseOffset, 2);
    });

    test('forward delete at a token start removes the whole token', () {
      final controller = _controller(':shortsad: b')
        ..selection = const TextSelection.collapsed(offset: 0);
      controller.value = const TextEditingValue(
        text: 'shortsad: b',
        selection: TextSelection.collapsed(offset: 0),
      );
      expect(controller.text, ' b');
    });

    test('caret cannot rest inside a token', () {
      final controller = _controller('a :shortsad: b');
      // Moving left from the token end jumps to its start.
      controller.selection = const TextSelection.collapsed(offset: 12);
      controller.selection = const TextSelection.collapsed(offset: 11);
      expect(controller.selection.baseOffset, 2);
      // Moving right from the token start jumps to its end.
      controller.selection = const TextSelection.collapsed(offset: 3);
      expect(controller.selection.baseOffset, 12);
    });

    test('unknown tokens are plain text', () {
      final controller = _controller('a :nope:');
      controller.value = const TextEditingValue(
        text: 'a :nope',
        selection: TextSelection.collapsed(offset: 7),
      );
      expect(controller.text, 'a :nope');
    });
  });

  group('DebouncedSearchBar emoji autocomplete', () {
    Future<List<String>> pumpBar(WidgetTester tester) async {
      final queries = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DebouncedSearchBar(
                hintText: 'Search',
                onQueryChanged: queries.add,
                emojis: const EmojiSearchConfig(
                  groups: [
                    ChannelEmojiGroup(
                      channelId: 'UC1',
                      channelTitle: 'Shylily',
                      emojis: [_shortsad, _shypraise],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return queries;
    }

    testWidgets('typing :sh suggests and Enter inserts the token', (
      tester,
    ) async {
      final queries = await pumpBar(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'lol :sho');
      await tester.pump();

      expect(find.text(':shortsad:'), findsOneWidget);
      expect(find.text(':shypraise:'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 400));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'lol :shortsad:');
      expect(queries.last, 'lol :shortsad:');
      expect(find.text(':shortsad:'), findsNothing); // overlay closed
    });

    testWidgets('arrow keys change the highlighted suggestion', (tester) async {
      await pumpBar(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), ':sh');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, ':shypraise:');
    });

    testWidgets('emoji button opens the picker and inserts at the caret', (
      tester,
    ) async {
      final queries = await pumpBar(tester);
      await tester.tap(find.byTooltip('Search by emoji'));
      await tester.pumpAndSettle();

      expect(find.text('SHYLILY'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(':shypraise:'));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, ':shypraise:');
      expect(queries.last, ':shypraise:');
    });

    // Desktop text fields select all on focus; inserting must not leave the
    // text selected or the next insert replaces it.
    testWidgets('inserting from the picker keeps a collapsed caret', (
      tester,
    ) async {
      await pumpBar(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'lol ');
      await tester.pump();

      for (final name in [':shypraise:', ':shortsad:']) {
        await tester.tap(find.byTooltip('Search by emoji'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel(name));
        await tester.pumpAndSettle(const Duration(milliseconds: 400));
      }

      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      expect(controller.text, 'lol :shypraise::shortsad:');
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, controller.text.length);
    }, variant: TargetPlatformVariant.desktop());
  });
}
