import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/quota/domain/quota_period.dart';

void main() {
  group('quotaPeriodStart', () {
    test('is midnight Pacific Standard Time in winter', () {
      expect(
        quotaPeriodStart(DateTime.utc(2026, 1, 15, 12)),
        DateTime.utc(2026, 1, 15, 8),
      );
    });

    test('is midnight Pacific Daylight Time in summer', () {
      expect(
        quotaPeriodStart(DateTime.utc(2026, 7, 1, 12)),
        DateTime.utc(2026, 7, 1, 7),
      );
    });

    test('turns over exactly at midnight Pacific', () {
      expect(
        quotaPeriodStart(DateTime.utc(2026, 1, 16, 7, 59, 59)),
        DateTime.utc(2026, 1, 15, 8),
      );
      expect(
        quotaPeriodStart(DateTime.utc(2026, 1, 16, 8)),
        DateTime.utc(2026, 1, 16, 8),
      );
      expect(
        quotaPeriodStart(DateTime.utc(2026, 7, 2, 6, 59, 59)),
        DateTime.utc(2026, 7, 1, 7),
      );
      expect(
        quotaPeriodStart(DateTime.utc(2026, 7, 2, 7)),
        DateTime.utc(2026, 7, 2, 7),
      );
    });

    test('ignores the time zone of the time passed in', () {
      final now = DateTime.utc(2026, 1, 15, 12);
      expect(quotaPeriodStart(now.toLocal()), quotaPeriodStart(now));
    });

    // Clocks spring forward on 8 March 2026 at 2 AM PST (10:00 UTC).
    group('on the day daylight time starts', () {
      final midnight = DateTime.utc(2026, 3, 8, 8);

      test('keeps the same period across the change', () {
        for (final now in [
          DateTime.utc(2026, 3, 8, 8),
          DateTime.utc(2026, 3, 8, 9, 59),
          DateTime.utc(2026, 3, 8, 10),
          DateTime.utc(2026, 3, 8, 10, 1),
          DateTime.utc(2026, 3, 9, 6, 59),
        ]) {
          expect(quotaPeriodStart(now), midnight, reason: '$now');
        }
      });

      test('starts the next period at midnight daylight time', () {
        expect(
          quotaPeriodStart(DateTime.utc(2026, 3, 9, 7)),
          DateTime.utc(2026, 3, 9, 7),
        );
      });
    });

    // Clocks fall back on 1 November 2026 at 2 AM PDT (09:00 UTC).
    group('on the day daylight time ends', () {
      final midnight = DateTime.utc(2026, 11, 1, 7);

      test('keeps the same period across the change', () {
        for (final now in [
          DateTime.utc(2026, 11, 1, 7),
          DateTime.utc(2026, 11, 1, 8, 59),
          DateTime.utc(2026, 11, 1, 9),
          DateTime.utc(2026, 11, 1, 9, 30),
          DateTime.utc(2026, 11, 2, 7, 59),
        ]) {
          expect(quotaPeriodStart(now), midnight, reason: '$now');
        }
      });

      test('starts the next period at midnight standard time', () {
        expect(
          quotaPeriodStart(DateTime.utc(2026, 11, 2, 8)),
          DateTime.utc(2026, 11, 2, 8),
        );
      });
    });
  });

  group('nextQuotaPeriodStart', () {
    test('is the next midnight Pacific', () {
      expect(
        nextQuotaPeriodStart(DateTime.utc(2026, 1, 15, 8)),
        DateTime.utc(2026, 1, 16, 8),
      );
    });

    test('is midnight daylight time after the clocks go forward', () {
      expect(
        nextQuotaPeriodStart(DateTime.utc(2026, 3, 8, 8)),
        DateTime.utc(2026, 3, 9, 7),
      );
    });

    test('is midnight standard time after the clocks go back', () {
      expect(
        nextQuotaPeriodStart(DateTime.utc(2026, 11, 1, 7)),
        DateTime.utc(2026, 11, 2, 8),
      );
    });
  });
}
