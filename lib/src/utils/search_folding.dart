/// Folds [text] for search: lowercases it, drops accents (whether written as
/// one character or as a letter plus a combining mark) and U+FE0F (the emoji
/// presentation selector, so `❤️` and `❤` match each other). Apply to both
/// the query and the searched text.
String foldForSearch(String text) => foldForSearchWithOffsets(text).folded;

/// [foldForSearch]'s result, plus the offset in [text] of each of its code
/// units, so a match in the folded text can be found in the original.
({String folded, List<int> offsets}) foldForSearchWithOffsets(String text) {
  final folded = StringBuffer();
  final offsets = <int>[];
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit == 0xFE0F || _isCombiningMark(unit)) continue;
    final lower = String.fromCharCode(unit).toLowerCase();
    for (final c in lower.codeUnits) {
      if (_isCombiningMark(c)) continue;
      final plain = _plainLetters[c];
      if (plain == null) {
        folded.writeCharCode(c);
        offsets.add(i);
      } else {
        folded.write(plain);
        for (var n = 0; n < plain.length; n++) {
          offsets.add(i);
        }
      }
    }
  }
  return (folded: folded.toString(), offsets: offsets);
}

bool _isCombiningMark(int unit) => unit >= 0x0300 && unit <= 0x036F;

/// Lowercase accented Latin letters, and letters written for two, by the
/// plain letters search treats them as.
final Map<int, String> _plainLetters = {
  for (final (letters, plain) in const [
    ('àáâãäåāăą', 'a'),
    ('çćĉċč', 'c'),
    ('ďđ', 'd'),
    ('èéêëēĕėęě', 'e'),
    ('ĝğġģ', 'g'),
    ('ĥħ', 'h'),
    ('ìíîïĩīĭįı', 'i'),
    ('ĵ', 'j'),
    ('ķ', 'k'),
    ('ĺļľŀł', 'l'),
    ('ñńņňŉ', 'n'),
    ('òóôõöøōŏő', 'o'),
    ('ŕŗř', 'r'),
    ('śŝşšſ', 's'),
    ('ţťŧ', 't'),
    ('ùúûüũūŭůűų', 'u'),
    ('ŵ', 'w'),
    ('ýÿŷ', 'y'),
    ('źżž', 'z'),
    ('ð', 'd'),
    ('ß', 'ss'),
    ('æ', 'ae'),
    ('œ', 'oe'),
    ('þ', 'th'),
  ])
    for (final letter in letters.codeUnits) letter: plain,
};
