import 'package:intl/intl.dart';

/// [count] of [noun], e.g. "1 comment" or "1,234 comments". Nouns whose
/// plural isn't [noun] plus "s" pass it as [plural].
String formatCount(int count, String noun, {String? plural}) => Intl.plural(
  count,
  one: '1 $noun',
  other:
      '${NumberFormat.decimalPattern().format(count)} ${plural ?? '${noun}s'}',
);

/// [share], from 0 to 1, as a whole percent, e.g. "41%"; "<1%" for a
/// sliver, so something is never shown as nothing.
String formatShare(double share) =>
    share > 0 && share < 0.005 ? '<1%' : '${(share * 100).round()}%';
