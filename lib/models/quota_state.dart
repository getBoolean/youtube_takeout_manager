import 'package:dart_mappable/dart_mappable.dart';

part 'quota_state.mapper.dart';

@MappableClass()
class QuotaState with QuotaStateMappable {
  static const int _costPerDelete = 50;

  final int unitsUsed;
  final DateTime periodStart;
  final int dailyLimit;

  const QuotaState({
    required this.unitsUsed,
    required this.periodStart,
    this.dailyLimit = 10000,
  });

  int get unitsRemaining => (dailyLimit - unitsUsed).clamp(0, dailyLimit);
  int get deletesRemaining => unitsRemaining ~/ _costPerDelete;
  bool get isExhausted => unitsRemaining < _costPerDelete;
}
