import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/actions_sheet.dart';

void main() {
  /// Opens a sheet of two options from a button, and returns what it picked.
  Future<Future<int?>> openSheet(WidgetTester tester) async {
    late Future<int?> picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => picked = showActionsSheet(
                context,
                options: const [
                  SheetOption(1, Icons.open_in_new, 'First'),
                  SheetOption(2, Icons.copy, 'Second', 'With a subtitle'),
                ],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('returns the option picked', (tester) async {
    final picked = await openSheet(tester);

    expect(find.text('With a subtitle'), findsOneWidget);
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();

    expect(await picked, 2);
  });

  testWidgets('dismissing it returns nothing', (tester) async {
    final picked = await openSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(await picked, isNull);
  });
}
