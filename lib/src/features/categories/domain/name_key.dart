import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

/// Punctuation, hyphens among it, spaces and other separators, and
/// invisible characters, in any script; but not a sharp, which tells C# from
/// C.
final _ignored = RegExp(r'(?!#)[\p{P}\p{Z}\p{C}]', unicode: true);

/// [name] folded for comparing names: case, accents, hyphens, spaces and
/// punctuation don't count, so "Hip-hop", "Hip hop" and "hiphop" share a
/// key. Symbols still count ("C++" isn't "C#"), as does a sharp ("C#" isn't
/// "C"), as do marks search keeps, such as Devanagari vowel signs. A name of
/// nothing but punctuation keeps a key of its own.
String nameKey(String name) {
  final folded = foldForSearch(name);
  final key = folded.replaceAll(_ignored, '');
  return key.isEmpty ? folded.trim() : key;
}

/// [text] folded and split into its words' keys, as [nameKey] makes them:
/// split wherever [nameKey] ignores a character, so a run of them joined
/// is the key of the name they spell.
List<String> nameKeyWords(String text) {
  final folded = foldForSearch(text);
  final words = <String>[];
  var start = 0;
  for (var i = 0; i < folded.length; i++) {
    if (_ignores(folded.codeUnitAt(i))) {
      if (i > start) words.add(folded.substring(start, i));
      start = i + 1;
    }
  }
  if (folded.length > start) words.add(folded.substring(start));
  return words;
}

/// Whether [nameKey] ignores the code unit [unit], looked up rather than
/// matched each time; half of a character outside the BMP, such as an
/// emoji, is kept.
bool _ignores(int unit) {
  if (unit < 0x80) return _asciiIgnored[unit];
  if (unit >= 0xD800 && unit <= 0xDFFF) return false;
  return _ignoredByUnit[unit] ??= _ignored.hasMatch(String.fromCharCode(unit));
}

final _asciiIgnored = List<bool>.generate(
  0x80,
  (unit) => _ignored.hasMatch(String.fromCharCode(unit)),
);
final _ignoredByUnit = <int, bool>{};
