/// One local day of history: its entries, as indices into the list they're
/// from, newest first.
typedef HistoryDay = ({int dayKey, DateTime day, List<int> indices});

/// A number that orders local days, `yyyymmdd`, for the local day [time]
/// falls on.
int dayKeyOf(DateTime time) {
  final local = time.toLocal();
  return local.year * 10000 + local.month * 100 + local.day;
}

/// Groups the entries at [indices], newest first, by their local day,
/// given each entry's [dayKeys] (from [dayKeyOf]).
List<HistoryDay> groupByDay(Iterable<int> indices, List<int> dayKeys) {
  final days = <HistoryDay>[];
  for (final i in indices) {
    final key = dayKeys[i];
    if (days.isEmpty || days.last.dayKey != key) {
      days.add((
        dayKey: key,
        day: DateTime(key ~/ 10000, key ~/ 100 % 100, key % 100),
        indices: [],
      ));
    }
    days.last.indices.add(i);
  }
  return days;
}

/// [days] (newest first) joined into local months, newest first: each a
/// [HistoryDay] whose key is `yyyymm00` and whose day is the month's first,
/// so the same lookups work on months as on days.
List<HistoryDay> monthsOf(List<HistoryDay> days) {
  final months = <HistoryDay>[];
  for (final day in days) {
    final key = day.dayKey ~/ 100 * 100;
    if (months.isEmpty || months.last.dayKey != key) {
      months.add((
        dayKey: key,
        day: DateTime(day.day.year, day.day.month),
        indices: [],
      ));
    }
    months.last.indices.addAll(day.indices);
  }
  return months;
}

/// The day of [days] (newest first) to show for [date]: that day, else the
/// nearest older one, else the oldest. Null when there are no days.
HistoryDay? dayGroupFor(List<HistoryDay> days, DateTime date) {
  if (days.isEmpty) return null;
  final key = date.year * 10000 + date.month * 100 + date.day;
  for (final day in days) {
    if (day.dayKey <= key) return day;
  }
  return days.last;
}

/// Which of [days] has the entry at [index], and where in it, or null when
/// none does. Days hold ascending indices, as [groupByDay] makes them, so
/// both are binary searches.
(int, int)? dayAndPositionOf(List<HistoryDay> days, int index) {
  var low = 0;
  var high = days.length - 1;
  // The last day whose first entry is at or before [index].
  while (low < high) {
    final mid = (low + high + 1) >> 1;
    if (days[mid].indices.first <= index) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  if (days.isEmpty || days[low].indices.first > index) return null;
  final indices = days[low].indices;
  var start = 0;
  var end = indices.length - 1;
  while (start <= end) {
    final mid = (start + end) >> 1;
    final at = indices[mid];
    if (at == index) return (low, mid);
    if (at < index) {
      start = mid + 1;
    } else {
      end = mid - 1;
    }
  }
  return null;
}
