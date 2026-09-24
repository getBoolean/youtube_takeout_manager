import 'quota_operation.dart';

class QuotaState {
  final Map<QuotaOperation, int> usageByOperation;
  final DateTime periodStart;
  final int dailyLimit;

  const QuotaState({
    required this.usageByOperation,
    required this.periodStart,
    this.dailyLimit = 10000,
  });

  int get unitsUsed => usageByOperation.values.fold(0, (a, b) => a + b);
  int get unitsRemaining => (dailyLimit - unitsUsed).clamp(0, dailyLimit);

  bool canAfford(int cost) => unitsRemaining >= cost;
  int affordableOperations(int costPerOp) => unitsRemaining ~/ costPerOp;
  int usageFor(QuotaOperation op) => usageByOperation[op] ?? 0;

  QuotaState copyWith({
    Map<QuotaOperation, int>? usageByOperation,
    DateTime? periodStart,
    int? dailyLimit,
  }) {
    return QuotaState(
      usageByOperation: usageByOperation ?? this.usageByOperation,
      periodStart: periodStart ?? this.periodStart,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }
}
