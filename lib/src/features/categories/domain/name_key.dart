import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

/// Everything but letters, their marks and digits, in any script.
final _notWordy = RegExp(r'[^\p{L}\p{M}\p{N}]', unicode: true);

/// [name] folded for comparing names: case, accents, hyphens, spaces and
/// punctuation don't count, so "Hip-hop", "Hip hop" and "hiphop" share a
/// key. Marks search keeps, such as Devanagari vowel signs, still count. A
/// name with no letters or digits keeps a key of its own.
String nameKey(String name) {
  final folded = foldForSearch(name);
  final key = folded.replaceAll(_notWordy, '');
  return key.isEmpty ? folded.trim() : key;
}
