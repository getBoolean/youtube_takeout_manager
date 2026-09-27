import 'package:intl/intl.dart';

/// [count] of [noun], e.g. "1 comment" or "1,234 comments". Nouns whose
/// plural isn't [noun] plus "s" pass it as [plural].
String formatCount(int count, String noun, {String? plural}) => Intl.plural(
  count,
  one: '1 $noun',
  other:
      '${NumberFormat.decimalPattern().format(count)} ${plural ?? '${noun}s'}',
);
