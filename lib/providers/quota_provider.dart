import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/quota_state.dart';
import '../services/quota_persistence_service.dart';
import '../services/youtube_deletion_service.dart';

part 'quota_provider.g.dart';

@Riverpod(keepAlive: true)
class QuotaNotifier extends _$QuotaNotifier {
  final _persistence = QuotaPersistenceService();

  @override
  Future<QuotaState> build() async {
    return _persistence.loadQuotaState();
  }

  /// Whether the current quota allows at least one more deletion.
  Future<bool> canDelete() async {
    final current = await future;
    return !current.isExhausted;
  }

  /// Records a single deletion's quota cost and persists the updated state.
  Future<void> recordDeletion() async {
    final current = await future;
    final updated = current.copyWith(
      unitsUsed: current.unitsUsed + YoutubeDeletionService.quotaCostPerDelete,
    );
    state = AsyncData(updated);
    await _persistence.saveQuotaState(updated);
  }

  /// Resets the quota if a new day has started (checked via persistence).
  Future<void> resetIfNewDay() async {
    final fresh = await _persistence.loadQuotaState();
    state = AsyncData(fresh);
  }
}
