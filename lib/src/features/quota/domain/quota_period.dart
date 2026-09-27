/// The start of the quota period containing [now], as UTC.
///
/// Google resets API quotas at midnight US Pacific time: UTC-8 (PST), or
/// UTC-7 (PDT) from the second Sunday of March to the first Sunday of
/// November.
DateTime quotaPeriodStart(DateTime now) {
  final utc = now.toUtc();
  final pacificNow = utc.add(Duration(hours: _isPacificDst(utc) ? -7 : -8));
  // Midnight comes before the 2 AM clock change, so on the days the clocks
  // change it's still in the previous offset.
  final standardMidnight = DateTime.utc(
    pacificNow.year,
    pacificNow.month,
    pacificNow.day,
    8,
  );
  return _isPacificDst(standardMidnight)
      ? standardMidnight.subtract(const Duration(hours: 1))
      : standardMidnight;
}

/// Whether US Pacific time is on daylight time at [utc].
bool _isPacificDst(DateTime utc) {
  final year = utc.year;

  // Second Sunday of March at 10:00 UTC (2 AM PST).
  final marchFirst = DateTime.utc(year, 3, 1);
  final firstSundayOfMarch = marchFirst.add(
    Duration(days: (7 - marchFirst.weekday) % 7),
  );
  final dstStart = firstSundayOfMarch.add(const Duration(days: 7, hours: 10));

  // First Sunday of November at 9:00 UTC (2 AM PDT).
  final novFirst = DateTime.utc(year, 11, 1);
  final firstSundayOfNov = novFirst.add(
    Duration(days: (7 - novFirst.weekday) % 7),
  );
  final dstEnd = firstSundayOfNov.add(const Duration(hours: 9));

  return utc.isAfter(dstStart) && utc.isBefore(dstEnd);
}
