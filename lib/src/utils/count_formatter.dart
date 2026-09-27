import 'package:intl/intl.dart';

/// [count] of [noun], e.g. "1 comment" or "1,234 comments".
String formatCount(int count, String noun) => Intl.plural(
  count,
  one: '1 $noun',
  other: '${NumberFormat.decimalPattern().format(count)} ${noun}s',
);
