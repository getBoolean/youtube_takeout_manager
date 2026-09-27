import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/takeout_import_request.dart';
import 'takeout_files.dart';

/// Extracts relevant CSV files from one or more Google Takeout zip archives.
///
/// Google Takeout splits large exports into multiple independent zip files
/// (e.g. takeout-*-001.zip, takeout-*-002.zip). Each is a standard zip archive
/// containing a subset of the exported files.
class ZipExtractor {
  /// Extracts the [TakeoutFile]s Google's takeouts have from [zips]. A zip
  /// on disk is read from its index, so the rest of it (e.g. videos) is
  /// never read.
  ///
  /// Returns a map of `<zip index>/<path in zip>` to file content bytes. The
  /// index keeps files with the same path in different zips apart.
  Map<String, Uint8List> extractRelevantFiles(List<PickedZip> zips) {
    final result = <String, Uint8List>{};

    for (final (i, zip) in zips.indexed) {
      final input = switch (zip) {
        PickedZipFile(:final path) => InputFileStream(path),
        PickedZipBytes(:final bytes) => InputMemoryStream(bytes),
      };
      try {
        final archive = ZipDecoder().decodeStream(input);
        for (final file in archive.files) {
          if (file.isFile &&
              (TakeoutFile.classify(file.name)?.fromGoogle ?? false)) {
            result['$i/${file.name}'] = file.content;
          }
        }
      } finally {
        input.closeSync();
      }
    }

    return result;
  }
}
