import 'package:intl/intl.dart';

final _dateTimeFormat = DateFormat('MMM d, y h:mm a');
final _dateOnlyFormat = DateFormat('MMM d, y');

/// Formats a DateTime for display in comment/chat tiles.
String formatDateTime(DateTime dateTime) {
  return _dateTimeFormat.format(dateTime.toLocal());
}

/// Formats a DateTime showing only the date portion.
String formatDateOnly(DateTime dateTime) {
  return _dateOnlyFormat.format(dateTime.toLocal());
}
