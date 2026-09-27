import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/confirmed_action_section.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    Future<void> Function() onConfirm,
  ) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ConfirmedActionSection(
          title: 'Cache',
          description: 'Saved images',
          icon: Icons.delete_outline,
          actionLabel: 'Clear cache',
          question: 'Clear the cache?',
          confirmLabel: 'Clear',
          done: 'Cache cleared',
          failed: "Couldn't clear the cache",
          onConfirm: onConfirm,
        ),
      ),
    ),
  );

  Future<void> pumpAndConfirm(
    WidgetTester tester,
    Future<void> Function() onConfirm,
  ) async {
    await pumpSection(tester, onConfirm);
    await tester.tap(find.text('Clear cache'));
    await tester.pump();
    await tester.tap(find.text('Clear'));
    await tester.pump();
  }

  testWidgets('Cancel backs out without running the action', (tester) async {
    var ran = false;
    await pumpSection(tester, () async => ran = true);

    await tester.tap(find.text('Clear cache'));
    await tester.pump();
    expect(find.text('Clear cache'), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(ran, isFalse);
    expect(find.text('Clear cache'), findsOneWidget);
  });

  testWidgets('says when it is done', (tester) async {
    await pumpAndConfirm(tester, () async {});

    expect(find.text('Cache cleared'), findsOneWidget);
  });

  testWidgets("shows an exception's message without its type", (tester) async {
    await pumpAndConfirm(tester, () async => throw Exception('disk is full'));

    final message = find.textContaining('disk is full');
    expect(message, findsOneWidget);
    expect(tester.widget<Text>(message).data, isNot(contains('Exception')));
  });

  testWidgets('reports an error, and can be tried again', (tester) async {
    await pumpAndConfirm(tester, () async => throw StateError('a bug'));

    expect(tester.takeException(), isA<StateError>());
    expect(find.text("Couldn't clear the cache"), findsOneWidget);
    expect(find.text('Clear cache'), findsOneWidget);
  });
}
