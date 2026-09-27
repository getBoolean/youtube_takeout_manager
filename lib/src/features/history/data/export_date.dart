/// Reads the dates of Google's HTML activity exports, e.g.
/// "Apr 12, 2026, 2:33:54 AM CDT" or "12 Apr 2026, 14:05:00 BST".
///
/// Google writes the whole export at one UTC offset, labelled with its zone
/// abbreviation, so the label says how far from UTC every date is. Only
/// English dates are read; exports in other languages give null.
DateTime? parseExportDate(String text, {required Duration localOffset}) {
  final normalized = text
      .replaceAll('\u202f', ' ')
      .replaceAll('\u00a0', ' ')
      .trim();
  final parts =
      _monthFirst.firstMatch(normalized) ?? _dayFirst.firstMatch(normalized);
  if (parts == null) return null;
  final month = _months[parts.namedGroup('month')!.toLowerCase()];
  if (month == null) return null;
  var hour = int.parse(parts.namedGroup('hour')!);
  switch (parts.namedGroup('ampm')) {
    case 'AM' when hour == 12:
      hour = 0;
    case 'PM' when hour != 12:
      hour += 12;
  }
  final (year, day, minute, second) = (
    int.parse(parts.namedGroup('year')!),
    int.parse(parts.namedGroup('day')!),
    int.parse(parts.namedGroup('minute')!),
    int.parse(parts.namedGroup('second')!),
  );
  final offset = _zoneOffset(parts.namedGroup('zone')!, localOffset);
  if (offset == null) {
    return DateTime(year, month, day, hour, minute, second).toUtc();
  }
  return DateTime.utc(year, month, day, hour, minute, second).subtract(offset);
}

const _time =
    r'(?<hour>\d{1,2}):(?<minute>\d{2}):(?<second>\d{2})(?: (?<ampm>AM|PM))?';
final _monthFirst = RegExp(
  '^(?<month>[A-Za-z]{3,4})\\.? (?<day>\\d{1,2}), (?<year>\\d{4}),? $_time '
  r'(?<zone>\S+)$',
);
final _dayFirst = RegExp(
  '^(?<day>\\d{1,2}) (?<month>[A-Za-z]{3,4})\\.? (?<year>\\d{4}),? $_time '
  r'(?<zone>\S+)$',
);

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
  'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

final _gmtOffset = RegExp(r'^(?:GMT|UTC)([+-])(\d{1,2})(?::?(\d{2}))?$');

/// How far [zone] is ahead of UTC, or null when it's unknown. Of the
/// offsets an ambiguous abbreviation can mean, the device's current one is
/// taken when it's among them, otherwise the first.
Duration? _zoneOffset(String zone, Duration localOffset) {
  if (_gmtOffset.firstMatch(zone) case final m?) {
    final minutes = int.parse(m[2]!) * 60 + int.parse(m[3] ?? '0');
    return Duration(minutes: m[1] == '-' ? -minutes : minutes);
  }
  final candidates = _zones[zone.toUpperCase()];
  if (candidates == null) return null;
  final offsets = [for (final hours in candidates) _hours(hours)];
  return offsets.contains(localOffset) ? localOffset : offsets.first;
}

Duration _hours(double hours) => Duration(minutes: (hours * 60).round());

/// Hours ahead of UTC of common zone abbreviations, most likely first.
const _zones = <String, List<double>>{
  'UTC': [0], 'GMT': [0], 'Z': [0], 'WET': [0], 'WEST': [1], //
  'BST': [1, 6], 'IST': [5.5, 1, 2], 'CET': [1], 'CEST': [2], 'MET': [1],
  'MEST': [2], 'EET': [2], 'EEST': [3], 'MSK': [3], 'SAST': [2],
  'WAT': [1], 'CAT': [2], 'EAT': [3], 'IDT': [3], 'PKT': [5],
  'NPT': [5.75], 'ICT': [7], 'WIB': [7], 'WITA': [8], 'WIT': [9],
  'HKT': [8], 'SGT': [8], 'PHT': [8], 'PHST': [8], 'AWST': [8],
  'JST': [9], 'KST': [9], 'ACST': [9.5], 'ACDT': [10.5], 'AEST': [10],
  'AEDT': [11], 'NZST': [12], 'NZDT': [13], 'CST': [-6, 8], 'CDT': [-5],
  'EST': [-5], 'EDT': [-4], 'MST': [-7], 'MDT': [-6], 'PST': [-8],
  'PDT': [-7], 'AKST': [-9], 'AKDT': [-8], 'HST': [-10], 'AST': [-4],
  'ADT': [-3], 'NST': [-3.5], 'NDT': [-2.5], 'BRT': [-3], 'ART': [-3],
};
