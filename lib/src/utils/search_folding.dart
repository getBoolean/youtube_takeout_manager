import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Folds [text] for search: lowercases it, drops accents and other marks
/// added to letters in any script (whether written as one character or as a
/// letter plus combining marks), and drops U+FE0F (the emoji presentation
/// selector, so `❤️` and `❤` match each other). Apply to both the query and
/// the searched text.
String foldForSearch(String text) => foldForSearchWithOffsets(text).folded;

/// [foldForSearch]'s result, plus the offset in [text] of each of its code
/// units, so a match in the folded text can be found in the original.
({String folded, List<int> offsets}) foldForSearchWithOffsets(String text) {
  final folded = StringBuffer();
  final offsets = <int>[];
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    final String plain;
    if (unit < 0x80) {
      plain = String.fromCharCode(unit).toLowerCase();
    } else if (unit == 0xFE0F || _isMark(unit)) {
      continue;
    } else if (unit >= 0xD800 && unit <= 0xDFFF) {
      // Half of a character outside the BMP, e.g. an emoji: kept as is.
      plain = String.fromCharCode(unit);
    } else {
      plain = _plainByUnit[unit] ??= _plain(unit);
    }
    folded.write(plain);
    for (var n = 0; n < plain.length; n++) {
      offsets.add(i);
    }
  }
  return (folded: folded.toString(), offsets: offsets);
}

/// Folded forms of the non-ASCII characters seen so far, as working them out
/// decomposes the character.
final _plainByUnit = <int, String>{};

/// [unit] lowercased, without the marks added to it.
String _plain(int unit) {
  final result = StringBuffer();
  for (final lower in String.fromCharCode(unit).toLowerCase().codeUnits) {
    if (_isMark(lower)) continue;
    final letter = String.fromCharCode(lower);
    if (_plainLetters[letter] case final plain?) {
      result.write(plain);
      continue;
    }
    // Only drop marks the decomposition adds: other decompositions (a voiced
    // kana, a Hangul syllable) make a letter of their own, kept whole.
    final parts = unorm.nfd(letter);
    final base = String.fromCharCodes(
      parts.codeUnits.where((c) => !_isMark(c)),
    );
    result.write(base.length < parts.length && base.isNotEmpty ? base : letter);
  }
  return result.toString();
}

/// Whether [unit] is a mark search ignores: accents and other diacritics,
/// and Hebrew and Arabic vowel marks.
bool _isMark(int unit) =>
    _between(unit, 0x0300, 0x036F) || // Combining diacritical marks
    _between(unit, 0x0483, 0x0489) || // Cyrillic
    _between(unit, 0x0591, 0x05BD) || // Hebrew points and accents
    unit == 0x05BF ||
    _between(unit, 0x05C1, 0x05C2) ||
    _between(unit, 0x05C4, 0x05C5) ||
    unit == 0x05C7 ||
    _between(unit, 0x0610, 0x061A) || // Arabic
    _between(unit, 0x064B, 0x065F) ||
    unit == 0x0670 ||
    _between(unit, 0x06D6, 0x06DC) ||
    _between(unit, 0x06DF, 0x06E4) ||
    _between(unit, 0x06E7, 0x06E8) ||
    _between(unit, 0x06EA, 0x06ED) ||
    _between(unit, 0x1AB0, 0x1AFF) || // Combining marks, extended
    _between(unit, 0x1DC0, 0x1DFF) || // Combining marks, supplement
    _between(unit, 0x20D0, 0x20FF) || // Combining marks for symbols
    _between(unit, 0xFE20, 0xFE2F); // Combining half marks

bool _between(int unit, int first, int last) => unit >= first && unit <= last;

/// Lowercase letters that don't decompose into a letter and marks, by the
/// letters search treats them as.
const _plainLetters = {
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
  'þ': 'th',
  'ð': 'd',
  'đ': 'd',
  'ħ': 'h',
  'ı': 'i',
  'ł': 'l',
  'ŀ': 'l',
  'ø': 'o',
  'ŧ': 't',
  'ſ': 's',
  'ŉ': 'n',
  'ς': 'σ',
};
