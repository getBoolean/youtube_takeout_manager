import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_status_bar.dart';

class _Quota extends QuotaNotifier {
  _Quota(this.quota);

  final QuotaState quota;

  @override
  Future<QuotaState> build() async => quota;
}

/// A little counted here, but YouTube saying the quota is used up.
final _usedUp = QuotaState(
  usageByOperation: {QuotaOperation.channelsList: 17},
  periodStart: DateTime.utc(2026, 9, 27, 7),
  usedUp: true,
);

Future<void> _pump(WidgetTester tester, {required bool compact}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [quotaProvider.overrideWith(() => _Quota(_usedUp))],
      child: MaterialApp(
        home: Scaffold(body: QuotaStatusBar(compact: compact)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final compact in [false, true]) {
    testWidgets('once YouTube says the quota is used up, the bar is full and '
        'says so${compact ? ', compact' : ''}', (tester) async {
      await _pump(tester, compact: compact);

      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      expect(find.byKey(QuotaStatusBar.usedUpKey), findsOneWidget);
    });
  }
}
