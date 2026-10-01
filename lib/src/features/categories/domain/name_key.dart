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
