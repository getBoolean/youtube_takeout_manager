import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'zip_picker_repository.g.dart';

@Riverpod(keepAlive: true)
ZipPickerRepository zipPickerRepository(Ref ref) => ZipPickerRepository();

/// Lets the user pick takeout zip files, read into memory.
class ZipPickerRepository {
  /// Opens the file picker for one or more zips. Returns null if cancelled.
  ///
  /// On web this must be called straight from a click handler, before any
  /// await, or the browser blocks the picker.
  Future<FilePickerResult?> pickZips() => FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
    allowMultiple: true,
    withData: true,
  );
}
