import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'takeout_files.dart';

/// Extracts relevant CSV files from one or more Google Takeout zip archives.
///
/// Google Takeout splits large exports into multiple independent zip files
/// (e.g. takeout-*-001.zip, takeout-*-002.zip). Each is a standard zip archive
/// containing a subset of the exported files.
class ZipExtractionService {
  /// Extracts the [TakeoutFile]s Google's takeouts have from the provided
  /// zip file bytes.
  ///
  /// Returns a map of `<zip index>/<path in zip>` to file content bytes. The
  /// index keeps files with the same path in different zips apart.
  Map<String, Uint8List> extractRelevantFiles(List<Uint8List> zipBytesList) {
    final result = <String, Uint8List>{};

    for (final (i, zipBytes) in zipBytesList.indexed) {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final file in archive.files) {
        if (file.isFile &&
            (TakeoutFile.classify(file.name)?.fromGoogle ?? false)) {
          result['$i/${file.name}'] = file.content;
        }
      }
    }

    return result;
  }
}
