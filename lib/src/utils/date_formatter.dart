import 'package:intl/intl.dart';

final _dateTimeFormat = DateFormat('MMM d, y h:mm a');

/// Formats a DateTime for display in comment/chat tiles.
String formatDateTime(DateTime dateTime) {
  return _dateTimeFormat.format(dateTime.toLocal());
}
