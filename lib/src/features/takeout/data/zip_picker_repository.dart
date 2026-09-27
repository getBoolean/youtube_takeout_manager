import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/takeout_import_plan.dart';
import '../domain/takeout_import_request.dart';

part 'zip_picker_repository.g.dart';

@Riverpod(keepAlive: true)
ZipPickerRepository zipPickerRepository(Ref ref) => ZipPickerRepository();

/// Lets the user pick takeout zip files, read into memory.
class ZipPickerRepository {
  final Future<FilePickerResult?> Function() _pickFiles;

  ZipPickerRepository({Future<FilePickerResult?> Function()? pickFiles})
    : _pickFiles = pickFiles ?? _pickZipFiles;

  /// Opens the file picker for one or more zips. Returns null if cancelled.
  /// Throws a [TakeoutImportException] if one couldn't be read.
  ///
  /// On web this must be called straight from a click handler, before any
  /// await, or the browser blocks the picker.
  Future<List<PickedZip>?> pickZips() async {
    final picked = await _pickFiles();
    if (picked == null) return null;
    return [
      for (final file in picked.files)
        (
          name: file.name,
          bytes:
              file.bytes ??
              (throw TakeoutImportException('Couldn\'t read "${file.name}".')),
        ),
    ];
  }
}

Future<FilePickerResult?> _pickZipFiles() => FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['zip'],
  allowMultiple: true,
  withData: true,
);
