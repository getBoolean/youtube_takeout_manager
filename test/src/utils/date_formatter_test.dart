import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';

void main() {
  // Local times, so the machine's time zone doesn't matter.
  final afternoon = DateTime(2026, 4, 12, 14, 5);

  test('a day reads with its weekday', () {
    expect(formatDay(afternoon), 'Sun, Apr 12, 2026');
  });

  test('a date reads month, day and year', () {
    expect(formatDate(afternoon), 'Apr 12, 2026');
  });

  test('a time reads as hours and minutes', () {
    expect(formatTime(afternoon), '2:05 PM');
  });

  test('UTC times are shown in local time', () {
    expect(formatTime(afternoon.toUtc()), '2:05 PM');
    expect(
      formatDay(DateTime(2026, 4, 12, 23, 59).toUtc()),
      'Sun, Apr 12, 2026',
    );
  });
}
