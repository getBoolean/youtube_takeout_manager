import 'dart:convert';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/quota_operation.dart';
import '../domain/quota_state.dart';

class QuotaPersistenceService {
  static const _key = 'quota_state';

  final _kv = KvStorageService();

  Future<QuotaState> loadQuotaState() async {
    final json = await _kv.getString(_key);
    if (json == null || json.isEmpty) return _freshState();

    final map = jsonDecode(json) as Map<String, dynamic>;
    final state = _fromJson(map);

    // Reset if we've crossed into a new quota period (midnight Pacific).
    if (_isNewQuotaPeriod(state.periodStart)) {
      return _freshState();
    }

    return state;
  }

  Future<void> saveQuotaState(QuotaState state) async {
    await _kv.setString(_key, jsonEncode(_toJson(state)));
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toJson(QuotaState state) {
    final usageMap = <String, int>{};
    for (final entry in state.usageByOperation.entries) {
      usageMap[entry.key.name] = entry.value;
    }
    return {
      'usageByOperation': usageMap,
      'periodStart': state.periodStart.toIso8601String(),
      'dailyLimit': state.dailyLimit,
    };
  }

  QuotaState _fromJson(Map<String, dynamic> map) {
    final periodStart = DateTime.parse(map['periodStart'] as String);
    final dailyLimit = map['dailyLimit'] as int? ?? 10000;

    // New format: usageByOperation map.
    if (map.containsKey('usageByOperation')) {
      final rawUsage = map['usageByOperation'] as Map<String, dynamic>;
      final usage = <QuotaOperation, int>{};
      for (final entry in rawUsage.entries) {
        final op = QuotaOperation.values.where((e) => e.name == entry.key);
        if (op.isNotEmpty) {
          usage[op.first] = entry.value as int;
        }
      }
      return QuotaState(
        usageByOperation: usage,
        periodStart: periodStart,
        dailyLimit: dailyLimit,
      );
    }

    // Legacy format: single unitsUsed integer → attribute to deleteComment.
    final legacyUnits = map['unitsUsed'] as int? ?? 0;
    return QuotaState(
      usageByOperation: legacyUnits > 0
          ? {QuotaOperation.deleteComment: legacyUnits}
          : {},
      periodStart: periodStart,
      dailyLimit: dailyLimit,
    );
  }

  // ---------------------------------------------------------------------------
  // Quota period helpers
  // ---------------------------------------------------------------------------

  /// Returns a fresh quota state with the current Pacific-day start.
  QuotaState _freshState() {
    return QuotaState(
      usageByOperation: {},
      periodStart: _currentPacificMidnight(),
    );
  }

  /// Whether the stored period start is before the most recent Pacific
  /// midnight, meaning the quota has reset.
  bool _isNewQuotaPeriod(DateTime periodStart) {
    return periodStart.isBefore(_currentPacificMidnight());
  }

  /// Computes the most recent midnight in US Pacific time as a UTC DateTime.
  ///
  /// Google resets API quotas at midnight Pacific.
  /// Pacific is UTC-8 (PST) or UTC-7 (PDT during DST).
  /// DST runs from the second Sunday of March to the first Sunday of November.
  DateTime _currentPacificMidnight() {
    final now = DateTime.now().toUtc();
    final pacificOffset = _isPacificDst(now) ? -7 : -8;
    final pacificNow = now.add(Duration(hours: pacificOffset));
    final pacificMidnight = DateTime.utc(
      pacificNow.year,
      pacificNow.month,
      pacificNow.day,
    );
    // Convert back to UTC by subtracting the offset.
    return pacificMidnight.subtract(Duration(hours: pacificOffset));
  }

  /// Rough DST check for US Pacific: DST is active from the second Sunday of
  /// March through the first Sunday of November.
  bool _isPacificDst(DateTime utc) {
    final year = utc.year;

    // Second Sunday of March at 10:00 UTC (2 AM PST).
    final marchFirst = DateTime.utc(year, 3, 1);
    final firstSundayOfMarch = marchFirst.add(
      Duration(days: (7 - marchFirst.weekday) % 7),
    );
    final secondSundayOfMarch = firstSundayOfMarch.add(const Duration(days: 7));
    final dstStart = secondSundayOfMarch.add(const Duration(hours: 10));

    // First Sunday of November at 9:00 UTC (2 AM PDT).
    final novFirst = DateTime.utc(year, 11, 1);
    final firstSundayOfNov = novFirst.add(
      Duration(days: (7 - novFirst.weekday) % 7),
    );
    final dstEnd = firstSundayOfNov.add(const Duration(hours: 9));

    return utc.isAfter(dstStart) && utc.isBefore(dstEnd);
  }
}
