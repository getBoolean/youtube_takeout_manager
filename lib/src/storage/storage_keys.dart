import 'dart:convert';

/// The most UTF-8 bytes a storage key can take: hive keeps a key's length
/// in one byte.
const maxKeyBytes = 255;

/// Whether [key] fits storage as it is.
bool keyFits(String key) =>
    key.length <= maxKeyBytes && utf8.encode(key).length <= maxKeyBytes;

/// A short, stable stand-in for [key]: two 32-bit FNV-1a hashes of its
/// UTF-8 bytes, as 16 hex digits.
String keyDigest(String key) {
  var first = 0x811c9dc5;
  var second = 0x01000193;
  for (final byte in utf8.encode(key)) {
    first = ((first ^ byte) * 0x01000193) & 0xFFFFFFFF;
    second = ((second ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  return '${first.toRadixString(16).padLeft(8, '0')}'
      '${second.toRadixString(16).padLeft(8, '0')}';
}
