import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/quota_operation.dart';
import '../models/quota_state.dart';
import '../services/quota_persistence_service.dart';

part 'quota_provider.g.dart';

@Riverpod(keepAlive: true)
class QuotaNotifier extends _$QuotaNotifier {
  final _persistence = QuotaPersistenceService();

  @override
  Future<QuotaState> build() async {
    return _persistence.loadQuotaState();
  }

  /// Whether the current quota can afford the given [cost].
  Future<bool> canAfford(int cost) async {
    final current = await future;
    return current.canAfford(cost);
  }

  /// Records quota usage for an [operation], optionally multiplied by [count].
  Future<void> recordUsage(QuotaOperation operation, {int count = 1}) async {
    final current = await future;
    final newUsage = Map<QuotaOperation, int>.from(current.usageByOperation);
    newUsage[operation] = (newUsage[operation] ?? 0) + (operation.cost * count);
    final updated = current.copyWith(usageByOperation: newUsage);
    state = AsyncData(updated);
    await _persistence.saveQuotaState(updated);
  }

  /// Resets all quota usage to zero.
  Future<void> resetUsage() async {
    final current = await future;
    final updated = current.copyWith(usageByOperation: {});
    state = AsyncData(updated);
    await _persistence.saveQuotaState(updated);
  }

  /// Resets the quota if a new day has started (checked via persistence).
  Future<void> resetIfNewDay() async {
    final fresh = await _persistence.loadQuotaState();
    state = AsyncData(fresh);
  }
}
