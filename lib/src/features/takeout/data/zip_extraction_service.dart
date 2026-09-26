import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'takeout_csv_encoder.dart';

/// Extracts relevant CSV files from one or more Google Takeout zip archives.
///
/// Google Takeout splits large exports into multiple independent zip files
/// (e.g. takeout-*-001.zip, takeout-*-002.zip). Each is a standard zip archive
/// containing a subset of the exported files.
class ZipExtractionService {
  /// Extracts comment CSVs, live chat CSVs, the subscriptions CSV, and the
  /// channel list and vanity names from the provided zip file bytes.
  ///
  /// Returns a map of `<zip index>/<path in zip>` to file content bytes. The
  /// index keeps files with the same path in different zips apart.
  Map<String, Uint8List> extractRelevantFiles(List<Uint8List> zipBytesList) {
    final result = <String, Uint8List>{};

    for (final (i, zipBytes) in zipBytesList.indexed) {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final file in archive.files) {
        if (file.isFile && _isRelevantPath(file.name)) {
          result['$i/${file.name}'] = file.content;
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
      if (lower.endsWith(channelsCsvPath)) return true;
      if (lower.endsWith(channelUrlConfigsCsvPath)) return true;
    }
    return false;
  }
}
