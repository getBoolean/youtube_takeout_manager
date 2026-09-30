import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/quota_repository.dart';
import '../domain/quota_operation.dart';
import '../domain/quota_state.dart';

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
  Future<void> recordUsage(QuotaOperation operation, {int count = 1}) =>
      _update((current) {
        final usage = Map<QuotaOperation, int>.from(current.usageByOperation);
        usage[operation] = (usage[operation] ?? 0) + (operation.cost * count);
        return current.copyWith(usageByOperation: usage);
      });

  /// Notes that YouTube refused a request because the quota is used up, so
  /// none is left until the next period.
  Future<void> markUsedUp() => _update(
    (current) => current.usedUp ? current : current.copyWith(usedUp: true),
  );

  /// Resets all quota usage to zero.
  Future<void> resetUsage() => _update(
    (current) => current.copyWith(usageByOperation: {}, usedUp: false),
  );

  Future<void> _saved = Future.value();

  /// Applies [change] to the quota as it is once loaded, not as it was when
  /// asked: several fetchers record usage at once, and each change builds
  /// on the one before. Saves in order, so the last save is the latest.
  Future<void> _update(QuotaState Function(QuotaState current) change) async {
    await future;
    final current = state.requireValue;
    final updated = change(current);
    if (identical(updated, current)) return;
    state = AsyncData(updated);
    await (_saved = _saved.then(
      (_) => _repository.saveQuotaState(state.requireValue),
      onError: (_) => _repository.saveQuotaState(state.requireValue),
    ));
  }

  /// Resets the quota if a new day has started (checked via persistence).
  Future<void> resetIfNewDay() async {
    final fresh = await _repository.loadQuotaState();
    state = AsyncData(fresh);
  }
}
