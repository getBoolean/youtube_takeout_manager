import 'package:intl/intl.dart';

final _dateTimeFormat = DateFormat('MMM d, y h:mm a');
final _dayFormat = DateFormat('EEE, MMM d, y');
final _timeFormat = DateFormat('h:mm a');
final _dateFormat = DateFormat('MMM d, y');
final _monthFormat = DateFormat('MMMM y');

/// The local month of [dateTime], e.g. "April 2026".
String formatMonth(DateTime dateTime) =>
    _monthFormat.format(dateTime.toLocal());

/// Formats a DateTime for display in comment/chat tiles.
String formatDateTime(DateTime dateTime) {
  return _dateTimeFormat.format(dateTime.toLocal());
}

/// The local day of [dateTime] with its weekday, e.g. "Sun, Apr 12, 2026".
String formatDay(DateTime dateTime) => _dayFormat.format(dateTime.toLocal());

/// The local date of [dateTime], e.g. "Apr 12, 2026".
String formatDate(DateTime dateTime) => _dateFormat.format(dateTime.toLocal());

/// The local time of day of [dateTime], e.g. "2:05 PM".
String formatTime(DateTime dateTime) => _timeFormat.format(dateTime.toLocal());
