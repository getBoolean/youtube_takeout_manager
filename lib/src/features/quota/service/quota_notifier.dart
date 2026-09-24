import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/quota_repository.dart';
import '../model/quota_operation.dart';
import '../model/quota_state.dart';

part 'quota_notifier.g.dart';

@Riverpod(keepAlive: true)
class QuotaNotifier extends _$QuotaNotifier {
  QuotaRepository get _repository => ref.read(quotaRepositoryProvider);

  @override
  Future<QuotaState> build() async {
    return ref.watch(quotaRepositoryProvider).loadQuotaState();
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
    await _repository.saveQuotaState(updated);
  }

  /// Resets all quota usage to zero.
  Future<void> resetUsage() async {
    final current = await future;
    final updated = current.copyWith(usageByOperation: {});
    state = AsyncData(updated);
    await _repository.saveQuotaState(updated);
  }

  /// Resets the quota if a new day has started (checked via persistence).
  Future<void> resetIfNewDay() async {
    final fresh = await _repository.loadQuotaState();
    state = AsyncData(fresh);
  }
}
