import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/data/quota_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('recorded usage counts each operation at its cost and is still there '
      'after a restart', () async {
    final c = container();
    final quota = c.read(quotaProvider.notifier);
    await c.read(quotaProvider.future);

    await quota.recordUsage(QuotaOperation.deleteComment, count: 3);
    await quota.recordUsage(QuotaOperation.videosList);

    for (final state in [
      c.read(quotaProvider).requireValue,
      await container().read(quotaProvider.future),
    ]) {
      expect(
        state.usageFor(QuotaOperation.deleteComment),
        3 * QuotaOperation.deleteComment.cost,
      );
      expect(
        state.usageFor(QuotaOperation.videosList),
        QuotaOperation.videosList.cost,
      );
      expect(
        state.unitsRemaining,
        dailyQuotaLimit -
            3 * QuotaOperation.deleteComment.cost -
            QuotaOperation.videosList.cost,
      );
    }
  });

  test(
    'usage recorded at the same time, as two fetchers can, all counts',
    () async {
      final c = container();
      final quota = c.read(quotaProvider.notifier);
      await c.read(quotaProvider.future);

      await Future.wait([
        quota.recordUsage(QuotaOperation.videosList),
        quota.recordUsage(QuotaOperation.channelsList),
        quota.recordUsage(QuotaOperation.videosList),
      ]);

      final state = await container().read(quotaProvider.future);
      expect(
        state.usageFor(QuotaOperation.videosList),
        2 * QuotaOperation.videosList.cost,
      );
      expect(
        state.usageFor(QuotaOperation.channelsList),
        QuotaOperation.channelsList.cost,
      );
    },
  );

  test('usage from an earlier quota period is gone once checked', () async {
    final c = container();
    final quota = c.read(quotaProvider.notifier);
    await c.read(quotaProvider.future);
    await quota.recordUsage(QuotaOperation.deleteComment);
    expect(c.read(quotaProvider).requireValue.unitsUsed, isPositive);

    // The saved usage's period ends, as when the app stays open overnight.
    final stored = c.read(quotaProvider).requireValue;
    await c
        .read(quotaRepositoryProvider)
        .saveQuotaState(
          stored.copyWith(
            periodStart: stored.periodStart.subtract(const Duration(days: 1)),
          ),
        );
    await quota.resetIfNewDay();

    final state = c.read(quotaProvider).requireValue;
    expect(state.unitsUsed, 0);
    expect(
      state.periodStart.isAfter(
        stored.periodStart.subtract(const Duration(days: 1)),
      ),
      isTrue,
    );
  });

  test('usage from the current period stays when checked', () async {
    final c = container();
    final quota = c.read(quotaProvider.notifier);
    await c.read(quotaProvider.future);
    await quota.recordUsage(QuotaOperation.deleteLiveChat);

    await quota.resetIfNewDay();

    expect(
      c
          .read(quotaProvider)
          .requireValue
          .usageFor(QuotaOperation.deleteLiveChat),
      QuotaOperation.deleteLiveChat.cost,
    );
  });

  test('once YouTube says the quota is used up, none is left, even after a '
      'restart', () async {
    final c = container();
    await c.read(quotaProvider.future);

    await c.read(quotaProvider.notifier).markUsedUp();

    for (final state in [
      c.read(quotaProvider).requireValue,
      await container().read(quotaProvider.future),
    ]) {
      expect(state.usedUp, isTrue);
      expect(state.unitsRemaining, 0);
      expect(state.canAfford(1), isFalse);
    }
  });

  test('a quota YouTube said was used up is back in the next period', () async {
    final c = container();
    await c.read(quotaProvider.future);
    await c.read(quotaProvider.notifier).markUsedUp();

    final stored = c.read(quotaProvider).requireValue;
    await c
        .read(quotaRepositoryProvider)
        .saveQuotaState(
          stored.copyWith(
            periodStart: stored.periodStart.subtract(const Duration(days: 1)),
          ),
        );
    await c.read(quotaProvider.notifier).resetIfNewDay();

    expect(c.read(quotaProvider).requireValue.usedUp, isFalse);
    expect(c.read(quotaProvider).requireValue.unitsRemaining, dailyQuotaLimit);
  });

  test('resetting usage gives back a quota YouTube said was used up', () async {
    final c = container();
    await c.read(quotaProvider.future);
    await c.read(quotaProvider.notifier).markUsedUp();

    await c.read(quotaProvider.notifier).resetUsage();

    expect(c.read(quotaProvider).requireValue.usedUp, isFalse);
  });
}
