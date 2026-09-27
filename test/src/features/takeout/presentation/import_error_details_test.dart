import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_error_details.dart';

const _nothingImported = ValueKey('nothing-imported');

Finder _inGroup(String group, Finder finder) =>
    find.descendant(of: find.byKey(ValueKey(group)), matching: finder);

void main() {
  Future<void> show(WidgetTester tester, Object error) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ImportErrorDetails(error: error)),
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

    expect(
      _inGroup(
        'import-error-expected-channels',
        find.textContaining('UCNvbaa8lnkDE7-qc3zcePLA'),
      ),
      findsOneWidget,
    );
    expect(
      _inGroup('import-error-found-channels', find.textContaining('UCother')),
      findsOneWidget,
    );
    expect(find.byKey(_nothingImported), findsOneWidget);
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

    expect(
      _inGroup('import-error-expected-channels', find.text('Boolean')),
      findsOneWidget,
    );
    expect(
      _inGroup('import-error-found-channels', find.text('Somebody Else')),
      findsOneWidget,
    );
    expect(find.textContaining('UCb'), findsOneWidget);
  });

  testWidgets('other problems show their message', (tester) async {
    await show(
      tester,
      const TakeoutImportException(
        'No comments, live chats or subscriptions were found in the selected '
        'files.',
      ),
    );

    expect(
      find.textContaining('No comments, live chats or subscriptions'),
      findsOneWidget,
    );
    expect(find.byKey(_nothingImported), findsOneWidget);
    expect(
      find.byKey(const ValueKey('import-error-found-channels')),
      findsNothing,
    );
  });

  testWidgets('unexpected errors show their message too', (tester) async {
    await show(tester, Exception('disk full'));

    expect(find.textContaining('disk full'), findsOneWidget);
    expect(find.byKey(_nothingImported), findsOneWidget);
  });

  test('an account mismatch is titled apart from other failures', () {
    const mismatch = TakeoutAccountMismatchException(
      'x',
      expectedChannelIds: {'UCa'},
      foundChannelIds: {'UCb'},
    );
    const other = TakeoutImportException('x');

    expect(importErrorTitle(mismatch), isNot(importErrorTitle(other)));
    expect(importErrorTitle(Exception('x')), importErrorTitle(other));
  });
}
