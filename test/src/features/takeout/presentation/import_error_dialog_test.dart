import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_error_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, TakeoutImportException error) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => ImportErrorDialog(error: error),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('an account mismatch names both channels', (tester) async {
    await open(
      tester,
      const TakeoutAccountMismatchException(
        'This takeout is from a different YouTube account than your current '
        'data.',
        expectedChannelIds: {'UCNvbaa8lnkDE7-qc3zcePLA'},
        foundChannelIds: {'UCother'},
      ),
    );

    expect(find.text('Different YouTube account'), findsOneWidget);
    expect(
      find.text('youtube.com/channel/UCNvbaa8lnkDE7-qc3zcePLA'),
      findsOneWidget,
    );
    expect(find.text('youtube.com/channel/UCother'), findsOneWidget);
    expect(find.text('Nothing was imported.'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(ImportErrorDialog), findsNothing);
  });

  testWidgets('other problems show their message', (tester) async {
    await open(
      tester,
      const TakeoutImportException(
        'No comments, live chats or subscriptions were found in the selected '
        'files.',
      ),
    );

    expect(find.text("Couldn't import takeout"), findsOneWidget);
    expect(
      find.textContaining('No comments, live chats or subscriptions'),
      findsOneWidget,
    );
    expect(find.text('Nothing was imported.'), findsOneWidget);
  });
}
