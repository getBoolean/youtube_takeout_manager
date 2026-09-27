import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/takeout_import_plan.dart';
import '../domain/takeout_import_request.dart';

part 'zip_picker_repository.g.dart';

@Riverpod(keepAlive: true)
ZipPickerRepository zipPickerRepository(Ref ref) => ZipPickerRepository();

/// Lets the user pick takeout zip files: where they are on desktop, or read
/// into memory on web, which has no file paths.
class ZipPickerRepository {
  final Future<FilePickerResult?> Function({required bool withData}) _pickFiles;

  /// Whether the picked zips are read into memory instead of kept by path.
  final bool _inMemory;

  ZipPickerRepository({
    Future<FilePickerResult?> Function({required bool withData})? pickFiles,
    bool inMemory = kIsWeb,
  }) : _pickFiles = pickFiles ?? _pickZipFiles,
       _inMemory = inMemory;

  /// Opens the file picker for one or more zips. Returns null if cancelled.
  /// Throws a [TakeoutImportException] if one couldn't be read.
  ///
  /// On web this must be called straight from a click handler, before any
  /// await, or the browser blocks the picker.
  Future<List<PickedZip>?> pickZips() async {
    final picked = await _pickFiles(withData: _inMemory);
    if (picked == null) return null;
    return [
      for (final file in picked.files)
        switch ((_inMemory, file.bytes, file.path)) {
          (true, final bytes?, _) => PickedZip.bytes(file.name, bytes),
          (false, _, final path?) => PickedZip.file(file.name, path),
          _ => throw TakeoutImportException('Couldn\'t read "${file.name}".'),
        },
    ];
  }
}

Future<FilePickerResult?> _pickZipFiles({required bool withData}) =>
    FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: true,
      withData: withData,
    );
