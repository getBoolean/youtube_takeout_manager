import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/common_widgets/search_match_marker.dart';

const _match = TextStyle(fontWeight: FontWeight.w900);
const _heart = '❤';
const _heartEmoji = '❤️';
const _fire = '\u{1F525}';

void main() {
  Future<void> pump(WidgetTester tester, Widget text) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: text)));

  /// Text highlighted with the match style.
  List<String> textMatches(WidgetTester tester) {
    final rich = tester.widget<Text>(find.byType(Text).first).textSpan!;
    final result = <String>[];
    rich.visitChildren((span) {
      if (span is TextSpan && span.style == _match) result.add(span.text!);
      return true;
    });
    return result;
  }

  /// Runs of matched emojis, one entry per marker.
  List<String> emojiMatches(WidgetTester tester) => [
    for (final match in tester.widgetList<SearchMatchedEmojis>(
      find.byType(SearchMatchedEmojis),
    ))
      match.emojis,
  ];

  Future<void> pumpText(WidgetTester tester, String text, String query) =>
      pump(tester, HighlightedText(text, query: query, matchStyle: _match));

  testWidgets('matches text case-insensitively', (tester) async {
    await pumpText(tester, 'Hello hello', 'HELLO');
    expect(textMatches(tester), ['Hello', 'hello']);
    expect(emojiMatches(tester), isEmpty);
  });

  testWidgets('matches text whatever its accents', (tester) async {
    await pumpText(tester, 'Café, café and cafe', 'CAFE');
    expect(textMatches(tester), ['Café', 'café', 'cafe']);

    await pumpText(tester, 'Straße 5', 'strasse');
    expect(textMatches(tester), ['Straße']);

    await pumpText(tester, 'İstanbul', 'istan');
    expect(textMatches(tester), ['İstan']);
  });

  testWidgets('marks matched emojis instead of styling them', (tester) async {
    await pumpText(tester, 'so lit $_fire', 'lit $_fire');
    expect(textMatches(tester), ['lit ']);
    expect(emojiMatches(tester), [_fire]);
  });

  testWidgets('a run of matched emojis gets one marker', (tester) async {
    await pumpText(tester, 'a $_fire$_fire$_fire b $_fire', _fire);
    expect(emojiMatches(tester), ['$_fire$_fire$_fire', _fire]);
  });

  testWidgets('❤️ and ❤ match each other', (tester) async {
    await pumpText(tester, 'a $_heart b', _heartEmoji);
    expect(emojiMatches(tester), [_heart]);

    await pumpText(tester, 'a $_heartEmoji b', _heart);
    expect(emojiMatches(tester), [_heartEmoji]);
  });

  testWidgets('never splits an emoji', (tester) async {
    const thumbsUpMedium = '\u{1F44D}\u{1F3FD}';
    await pumpText(tester, 'ok $thumbsUpMedium', '\u{1F44D}');
    expect(emojiMatches(tester), [thumbsUpMedium]);
  });

  testWidgets('a run split across spans gets one marker', (tester) async {
    await pump(
      tester,
      const HighlightedText.rich([
        TextSpan(text: 'so $_fire'),
        TextSpan(text: _fire),
      ], query: _fire),
    );
    expect(emojiMatches(tester), ['$_fire$_fire']);
  });

  testWidgets('marks emojis once their glyphs are measured', (tester) async {
    await pumpText(tester, 'so lit $_fire', _fire);
    final marker = find.descendant(
      of: find.byType(SearchMatchedEmojis),
      matching: find.byType(SearchMatchMarker),
    );

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(marker, findsOneWidget);
    expect(
      find.descendant(of: marker, matching: find.text(_fire)),
      findsOneWidget,
    );
  });

  testWidgets('no highlight without a match', (tester) async {
    await pumpText(tester, 'plain $_fire', 'x');
    expect(textMatches(tester), isEmpty);
    expect(emojiMatches(tester), isEmpty);
  });
}
