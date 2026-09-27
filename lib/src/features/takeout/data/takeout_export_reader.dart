import '../domain/takeout_export.dart';
import '../domain/takeout_import_plan.dart';
import '../domain/takeout_import_request.dart';
import 'takeout_parser.dart';
import 'zip_extractor.dart';

/// The export time Google puts in takeout zip names, e.g.
/// `takeout-20260412T074021Z-3-001.zip`.
final _exportTime = RegExp(r'takeout-(\d{8}t\d{6}z)', caseSensitive: false);

/// Reads picked takeout zips, the parts of each export together. Throws a
/// [TakeoutImportException] when they can't be told apart or hold no
/// takeout data.
List<TakeoutExport> readTakeoutExports(List<PickedZip> zips) {
  final zipsByExport = <DateTime?, List<PickedZip>>{};
  for (final zip in zips) {
    final time = _exportTime.firstMatch(zip.name)?.group(1)?.toUpperCase();
    zipsByExport
        .putIfAbsent(time != null ? DateTime.parse(time) : null, () => [])
        .add(zip);
  }

  if (zipsByExport.length > 1 && zipsByExport.containsKey(null)) {
    final names = zipsByExport[null]!.map((z) => '"${z.name}"').join(', ');
    throw TakeoutImportException(
      "Can't tell which takeout $names belongs to. Keep the original "
      'takeout-… file names, or add one takeout at a time.',
    );
  }

  final exports = <TakeoutExport>[];
  for (final MapEntry(key: exportedAt, value: zips) in zipsByExport.entries) {
    final files = ZipExtractor().extractRelevantFiles([
      for (final zip in zips) zip.bytes,
    ]);
    if (files.isEmpty) continue;
    exports.add(parseTakeoutFiles(files, exportedAt: exportedAt));
  }
  if (exports.isEmpty) {
    throw const TakeoutImportException(
      'No comments, live chats or subscriptions were found in the selected '
      'files.',
    );
  }
  return exports;
}
