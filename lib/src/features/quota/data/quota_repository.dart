import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/quota_period.dart';
import '../domain/quota_state.dart';

part 'quota_repository.g.dart';

@Riverpod(keepAlive: true)
QuotaRepository quotaRepository(Ref ref) =>
    QuotaRepository(ref.watch(kvStorageServiceProvider));

class QuotaRepository {
  static const _key = 'quota_state';

  final KvStorageService _kv;

  QuotaRepository(this._kv);

  /// Today's usage, or none once a new quota period has started.
  Future<QuotaState> loadQuotaState() async {
    final periodStart = quotaPeriodStart(DateTime.now());
    final json = await _kv.getString(_key);
    if (json == null || json.isEmpty) return _freshState(periodStart);

    final state = QuotaStateMapper.fromJson(json);
    if (state.periodStart.isBefore(periodStart)) {
      return _freshState(periodStart);
    }
    return state;
  }

  Future<void> saveQuotaState(QuotaState state) async {
    await _kv.setString(_key, state.toJson());
  }

  QuotaState _freshState(DateTime periodStart) =>
      QuotaState(usageByOperation: const {}, periodStart: periodStart);
}
