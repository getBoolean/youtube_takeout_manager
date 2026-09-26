import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_error_details.dart';

void main() {
  Future<void> show(WidgetTester tester, TakeoutImportException error) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Text(importErrorTitle(error)),
                ImportErrorDetails(error: error),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('an account mismatch names both channels', (tester) async {
    await show(
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
  });

  testWidgets('other problems show their message', (tester) async {
    await show(
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

  testWidgets('names the channels by title when the takeouts give them', (
    tester,
  ) async {
    await show(
      tester,
      const TakeoutAccountMismatchException(
        'The selected takeouts are from different YouTube accounts.',
        expectedChannelIds: {'UCa'},
        foundChannelIds: {'UCb'},
        titlesById: {'UCa': 'Boolean', 'UCb': 'Somebody Else'},
      ),
    );

    expect(find.text('Boolean'), findsOneWidget);
    expect(find.text('Somebody Else'), findsOneWidget);
    expect(find.text('youtube.com/channel/UCb'), findsOneWidget);
  });
}
