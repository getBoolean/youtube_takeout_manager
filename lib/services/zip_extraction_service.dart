import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Extracts relevant CSV files from one or more Google Takeout zip archives.
///
/// Google Takeout splits large exports into multiple independent zip files
/// (e.g. takeout-*-001.zip, takeout-*-002.zip). Each is a standard zip archive
/// containing a subset of the exported files.
class ZipExtractionService {
  /// Extracts comment CSVs, live chat CSVs, and subscriptions CSV from the
  /// provided zip file bytes.
  ///
  /// Returns a map of relative file path to file content bytes.
  Map<String, Uint8List> extractRelevantFiles(List<Uint8List> zipBytesList) {
    final result = <String, Uint8List>{};

    for (final zipBytes in zipBytesList) {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final file in archive.files) {
        if (file.isFile && _isRelevantPath(file.name)) {
          result[file.name] = file.content;
        }
      }
    }

    return result;
  }

  bool _isRelevantPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.csv')) {
      if (lower.contains('comments/comments')) return true;
      if (lower.contains('live chats/live chats')) return true;
      if (lower.contains('subscriptions/subscriptions')) return true;
    }
    return false;
  }
}
