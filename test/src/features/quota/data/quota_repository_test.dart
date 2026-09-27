import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/quota/data/quota_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_state.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _key = 'flutter.quota_state';

void main() {
  QuotaRepository repository() => QuotaRepository(KvStorageService());

  // Stored during the current quota period, so it isn't reset on load.
  final periodStart = DateTime.now().toUtc();
  final storedStart = periodStart.toIso8601String();

  test('loads usage stored in the current format', () async {
    SharedPreferences.setMockInitialValues({
      _key:
          '{"usageByOperation":{"deleteComment":100,"deleteLiveChat":50,'
          '"videosList":3},"periodStart":"$storedStart","dailyLimit":10000}',
    });
    final state = await repository().loadQuotaState();

    expect(state.usageByOperation, {
      QuotaOperation.deleteComment: 100,
      QuotaOperation.deleteLiveChat: 50,
      QuotaOperation.videosList: 3,
    });
    expect(state.periodStart, periodStart);
    expect(state.dailyLimit, 10000);
    expect(state.unitsUsed, 153);
  });

  test('skips operations it no longer knows', () async {
    SharedPreferences.setMockInitialValues({
      _key:
          '{"usageByOperation":{"deleteComment":50,"playlistsList":7},'
          '"periodStart":"$storedStart","dailyLimit":10000}',
    });
    final state = await repository().loadQuotaState();

    expect(state.usageByOperation, {QuotaOperation.deleteComment: 50});
  });

  test('loads the legacy single total as deletes', () async {
    SharedPreferences.setMockInitialValues({
      _key: '{"unitsUsed":150,"periodStart":"$storedStart"}',
    });
    final state = await repository().loadQuotaState();

    expect(state.usageByOperation, {QuotaOperation.deleteComment: 150});
    expect(state.periodStart, periodStart);
    expect(state.dailyLimit, 10000);
  });

  test('loads a legacy total of zero as no usage', () async {
    SharedPreferences.setMockInitialValues({
      _key: '{"unitsUsed":0,"periodStart":"$storedStart","dailyLimit":500}',
    });
    final state = await repository().loadQuotaState();

    expect(state.usageByOperation, isEmpty);
    expect(state.dailyLimit, 500);
  });

  test('starts afresh once a new quota period began', () async {
    SharedPreferences.setMockInitialValues({
      _key:
          '{"usageByOperation":{"deleteComment":100},'
          '"periodStart":"2020-01-01T08:00:00.000Z","dailyLimit":10000}',
    });
    final state = await repository().loadQuotaState();

    expect(state.usageByOperation, isEmpty);
    expect(state.periodStart.isAfter(DateTime.utc(2020, 1, 2)), isTrue);
  });

  test('saves usage in the current format', () async {
    SharedPreferences.setMockInitialValues({});
    await repository().saveQuotaState(
      QuotaState(
        usageByOperation: {
          QuotaOperation.deleteComment: 100,
          QuotaOperation.channelsList: 2,
        },
        periodStart: DateTime.utc(2026, 9, 26, 7),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('quota_state'),
      '{"usageByOperation":{"deleteComment":100,"channelsList":2},'
      '"periodStart":"2026-09-26T07:00:00.000Z","dailyLimit":10000}',
    );
  });
}
