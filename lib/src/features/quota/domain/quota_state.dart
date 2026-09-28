import 'package:dart_mappable/dart_mappable.dart';

import 'quota_operation.dart';

part 'quota_state.mapper.dart';

/// The YouTube Data API's default daily quota, in units.
const dailyQuotaLimit = 10000;

@MappableClass(hook: _LegacyQuotaHook())
class QuotaState with QuotaStateMappable {
  final Map<QuotaOperation, int> usageByOperation;
  final DateTime periodStart;
  final int dailyLimit;

  /// Whether YouTube refused a request because the quota is used up: then
  /// none is left until the next period, whatever was counted here, as
  /// other apps may share it.
  final bool usedUp;

  const QuotaState({
    required this.usageByOperation,
    required this.periodStart,
    this.dailyLimit = dailyQuotaLimit,
    this.usedUp = false,
  });

  int get unitsUsed => usageByOperation.values.fold(0, (a, b) => a + b);
  int get unitsRemaining =>
      usedUp ? 0 : (dailyLimit - unitsUsed).clamp(0, dailyLimit);

  bool canAfford(int cost) => unitsRemaining >= cost;
  int affordableOperations(int costPerOp) => unitsRemaining ~/ costPerOp;
  int usageFor(QuotaOperation op) => usageByOperation[op] ?? 0;
}

/// Reads usage saved by older versions: a single `unitsUsed` total, counted
/// as comment deletes, and operations this version no longer has, dropped.
class _LegacyQuotaHook extends MappingHook {
  const _LegacyQuotaHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is! Map<String, dynamic>) return value;
    final known = {for (final op in QuotaOperation.values) op.name};
    final usage = value['usageByOperation'];
    if (usage is Map<String, dynamic>) {
      return {
        ...value,
        'usageByOperation': {
          for (final MapEntry(:key, value: units) in usage.entries)
            if (known.contains(key)) key: units,
        },
      };
    }
    final legacyUnits = value['unitsUsed'] as int? ?? 0;
    return {
      ...value,
      'usageByOperation': {
        if (legacyUnits > 0) QuotaOperation.deleteComment.name: legacyUnits,
      },
    };
  }
}
