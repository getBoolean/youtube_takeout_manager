import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/history/application/history_grouping.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('a first open groups by Channel', () async {
    expect(
      await container().read(historyGroupingProvider.future),
      HistoryGrouping.channel,
    );
  });

  test('a grouping picked is shown at once, and still picked after a '
      'restart', () async {
    final first = container();
    await first.read(historyGroupingProvider.future);

    final saved = first
        .read(historyGroupingProvider.notifier)
        .set(HistoryGrouping.month);
    expect(first.read(historyGroupingProvider).value, HistoryGrouping.month);
    await saved;

    expect(
      await container().read(historyGroupingProvider.future),
      HistoryGrouping.month,
    );
  });

  test('a saved grouping there no longer is, or nonsense, reads as '
      'Channel', () async {
    for (final saved in ['category', '', '42']) {
      SharedPreferences.setMockInitialValues({
        'flutter.history.grouping': saved,
      });

      expect(
        await container().read(historyGroupingProvider.future),
        HistoryGrouping.channel,
        reason: saved,
      );
    }
  });
}
