import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/sign_in_flow.dart';

const _chosen = SignInProfile(channelId: 'UCalt', channelTitle: 'Gaming Alt');

void main() {
  Future<bool?> open(WidgetTester tester, {required bool canView}) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<bool>(
              context: context,
              builder: (_) => SignedInOtherChannelDialog(
                chosen: _chosen,
                targetChannelId: 'UCme',
                targetTitle: 'Boolean',
                canViewChosen: canView,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets("offers to view the chosen channel's takeout", (tester) async {
    await open(tester, canView: true);

    await tester.tap(find.text('View Gaming Alt'));
    await tester.pumpAndSettle();

    expect(find.byType(SignedInOtherChannelDialog), findsNothing);
  });

  testWidgets('returns whether to view it', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDialog<bool>(
              context: context,
              builder: (_) => const SignedInOtherChannelDialog(
                chosen: _chosen,
                targetChannelId: 'UCme',
                canViewChosen: true,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Gaming Alt'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('without a saved takeout for it, only acknowledges', (
    tester,
  ) async {
    await open(tester, canView: false);

    expect(find.textContaining('View '), findsNothing);
    expect(find.text('OK'), findsOneWidget);
  });
}
