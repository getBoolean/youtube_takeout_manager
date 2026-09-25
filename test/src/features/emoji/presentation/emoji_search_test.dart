import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/data/unicode_emoji_catalog.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/channel_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/debounced_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_picker_panel.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
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

const _customFire = ChannelEmoji(
  key: 'k3',
  url: 'https://yt3.ggpht.com/k3',
  name: 'fire',
  channelId: 'UC1',
  usageCount: 2,
  resolved: true,
);
const _shylily = [
  ChannelEmojiGroup(
    channelId: 'UC1',
    channelTitle: 'Shylily',
    emojis: [_shortsad, _shypraise],
  ),
];
const _fire = '\u{1F525}';

EmojiTextEditingController _controller(String text) =>
    EmojiTextEditingController()
      ..emojisByName = {'shortsad': _shortsad}
      ..value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );

/// Records text copied to the clipboard.
ValueNotifier<String?> mockClipboard(WidgetTester tester) {
  final copied = ValueNotifier<String?>(null);
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.value = (call.arguments as Map)['text'] as String?;
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return copied;
}

/// Types [char] at the caret, like a keyboard.
void _type(EmojiTextEditingController controller, String char) {
  final caret = controller.selection.baseOffset;
  controller.value = TextEditingValue(
    text: controller.text.replaceRange(caret, caret, char),
    selection: TextSelection.collapsed(offset: caret + char.length),
  );
}

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

  group('EmojiTextEditingController shortcodes', () {
    EmojiTextEditingController typing(
      String text, {
      Map<String, ChannelEmoji> channelEmojis = const {},
      ValueChanged<UnicodeEmoji>? onConverted,
    }) => EmojiTextEditingController()
      ..unicodeEmojisByName = unicodeEmojiCatalog.byShortName
      ..onShortcodeConverted = onConverted
      ..emojisByName = channelEmojis
      ..value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );

    test('typing the closing colon converts a standard :name:', () {
      final converted = <String>[];
      final controller = typing(
        'hi :fire',
        onConverted: (e) => converted.add(e.shortName),
      );
      _type(controller, ':');
      expect(controller.text, 'hi $_fire');
      expect(controller.selection.baseOffset, controller.text.length);
      expect(converted, ['fire']);
    });

    test('a channel emoji with the same name wins', () {
      final controller = typing(
        'hi :fire',
        channelEmojis: {'fire': _customFire},
      );
      _type(controller, ':');
      expect(controller.text, 'hi :fire:');
    });

    test('leaves other colons alone', () {
      for (final text in [':nope', ':_fire', 'x:fire', '10:30']) {
        final controller = typing(text);
        _type(controller, ':');
        expect(controller.text, '$text:');
      }
    });

    test('a pasted :name: is not converted', () {
      final controller = typing('hi :fire:');
      expect(controller.text, 'hi :fire:');
    });

    test('nothing converts without a catalog', () {
      final controller = typing('hi :fire')..unicodeEmojisByName = const {};
      _type(controller, ':');
      expect(controller.text, 'hi :fire:');
    });
  });

  group('DebouncedSearchBar emoji autocomplete', () {
    Future<List<String>> pumpBar(
      WidgetTester tester, {
      List<ChannelEmojiGroup> groups = _shylily,
      List<UnicodeEmoji>? standard,
    }) async {
      final queries = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DebouncedSearchBar(
                hintText: 'Search',
                onQueryChanged: queries.add,
                emojis: EmojiSearchConfig(
                  groups: groups,
                  standardEmojis: standard ?? unicodeEmojiCatalog.all,
                ),
              ),
            ),
          ),
        ),
      );
      return queries;
    }

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).first).controller!.text;

    Future<void> openPicker(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Search by emoji'));
      await tester.pumpAndSettle();
    }

    Future<void> findInPicker(WidgetTester tester, String text) async {
      await tester.enterText(
        find.descendant(
          of: find.byType(EmojiPickerPanel),
          matching: find.byType(TextField),
        ),
        text,
      );
      await tester.pump();
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

    testWidgets('picker lists standard emojis by category', (tester) async {
      await pumpBar(tester);
      await openPicker(tester);

      expect(find.text('SHYLILY'), findsOneWidget);
      expect(find.text('PEOPLE'), findsOneWidget);
      expect(find.text('FREQUENTLY USED'), findsNothing);
    });

    testWidgets('finding and picking a standard emoji inserts it', (
      tester,
    ) async {
      final queries = await pumpBar(tester);
      await openPicker(tester);
      await findInPicker(tester, 'fire');

      expect(find.text('SHYLILY'), findsNothing);
      await tester.tap(find.bySemanticsLabel(':fire:'));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(fieldText(tester), _fire);
      expect(queries.last, _fire);
    });

    testWidgets('picked emojis show under Frequently Used', (tester) async {
      await pumpBar(tester);
      await openPicker(tester);
      await findInPicker(tester, 'fire');
      await tester.tap(find.bySemanticsLabel(':fire:'));
      await tester.pumpAndSettle();

      await openPicker(tester);
      expect(find.text('FREQUENTLY USED'), findsOneWidget);
      expect(find.bySemanticsLabel(':fire:'), findsWidgets);

      // Hidden while filtering, like Discord.
      await findInPicker(tester, 'fire');
      expect(find.text('FREQUENTLY USED'), findsNothing);
    });

    testWidgets('the rail jumps to a category', (tester) async {
      await pumpBar(tester);
      await openPicker(tester);
      expect(find.text('FLAGS').hitTestable(), findsNothing);

      final rail = find.descendant(
        of: find.byType(EmojiPickerPanel),
        matching: find.byType(ListView),
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Flags'),
        100,
        scrollable: find.descendant(
          of: rail,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byTooltip('Flags'));
      await tester.pumpAndSettle();

      expect(find.text('FLAGS').hitTestable(), findsOneWidget);
    });

    testWidgets('standard emojis are offered without channel emojis', (
      tester,
    ) async {
      await pumpBar(tester, groups: const []);
      await openPicker(tester);

      expect(find.text('PEOPLE'), findsOneWidget);
    });

    testWidgets('offers only the given standard emojis', (tester) async {
      final fire = unicodeEmojiCatalog.byShortName['fire']!;
      await pumpBar(tester, standard: [fire]);
      await openPicker(tester);

      expect(find.text('NATURE'), findsOneWidget);
      expect(find.text('PEOPLE'), findsNothing);
      expect(find.byTooltip('People'), findsNothing);
      expect(find.bySemanticsLabel(':fire:'), findsOneWidget);
      expect(find.bySemanticsLabel(':grinning:'), findsNothing);

      // Suggestions and typed names are limited the same way.
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), ':fi');
      await tester.pump();
      expect(find.text(':fire:'), findsOneWidget);
      expect(find.text(':fish:'), findsNothing);

      await tester.enterText(find.byType(TextField), ':fish');
      await tester.enterText(find.byType(TextField), ':fish:');
      await tester.pump();
      expect(fieldText(tester), ':fish:');
    });

    testWidgets('a channel emoji can copy its image URL', (tester) async {
      final clipboard = mockClipboard(tester);
      await pumpBar(tester);
      await openPicker(tester);

      await tester.tap(
        find.bySemanticsLabel(':shypraise:'),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy image URL'));
      await tester.pumpAndSettle();

      expect(clipboard.value, _shypraise.url);
      expect(find.text('SHYLILY'), findsOneWidget); // picker still open

      // A click elsewhere in the picker dismisses the menu, not the picker.
      // (The mouse now hovers the emoji, so the footer names it too.)
      await tester.tap(
        find.bySemanticsLabel(':shypraise:').first,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(find.text('Copy image URL'), findsOneWidget);
      await tester.tap(find.text('SHYLILY'));
      await tester.pumpAndSettle();
      expect(find.text('Copy image URL'), findsNothing);
      expect(find.text('SHYLILY'), findsOneWidget);

      // Long press works too, for touch.
      await tester.longPress(find.bySemanticsLabel(':shortsad:'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy image URL'));
      await tester.pumpAndSettle();
      expect(clipboard.value, _shortsad.url);
    });

    testWidgets('no emoji button without any emojis', (tester) async {
      await pumpBar(tester, groups: const [], standard: const []);
      expect(find.byTooltip('Search by emoji'), findsNothing);
    });

    testWidgets(':fir suggests 🔥 and Enter inserts it', (tester) async {
      await pumpBar(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'lit :fir');
      await tester.pump();

      expect(find.text(':fire:'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(fieldText(tester), 'lit $_fire');
    });

    testWidgets('typing :fire: converts it', (tester) async {
      final queries = await pumpBar(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), ':fire');
      await tester.enterText(find.byType(TextField), ':fire:');
      await tester.pump(const Duration(milliseconds: 400));

      expect(fieldText(tester), _fire);
      expect(queries.last, _fire);
    });

    testWidgets('a channel emoji and a standard one can share a name', (
      tester,
    ) async {
      await pumpBar(
        tester,
        groups: const [
          ChannelEmojiGroup(channelId: 'UC1', emojis: [_customFire]),
        ],
      );
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), ':fire');
      await tester.pump();

      // The channel emoji first, then the standard one.
      expect(find.text(':fire:'), findsNWidgets(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(fieldText(tester), _fire);

      // Typing the name in full keeps the channel emoji.
      await tester.enterText(find.byType(TextField), ':fire');
      await tester.enterText(find.byType(TextField), ':fire:');
      await tester.pump();
      expect(fieldText(tester), ':fire:');
    });

    testWidgets('clicking an emoji in the field places the caret', (
      tester,
    ) async {
      await pumpBar(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'a :shortsad: b');
      await tester.pump();

      await tester.tap(find.byType(EmojiPreview));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(':shortsad:'), findsNothing); // no preview
      final selection = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .selection;
      expect(selection.isCollapsed, isTrue);
      expect(selection.baseOffset, anyOf(2, 12));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('a time is not an emoji name', (tester) async {
      await pumpBar(tester);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'at 10:30');
      await tester.pump();

      expect(find.textContaining('EMOJI MATCHING'), findsNothing);
    });
  });
}
