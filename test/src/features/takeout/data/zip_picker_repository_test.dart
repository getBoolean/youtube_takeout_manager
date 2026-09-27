import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';

ZipPickerRepository _picking(List<PlatformFile>? files) => ZipPickerRepository(
  pickFiles: () async => files == null ? null : FilePickerResult(files),
);

void main() {
  test('reads the picked zips', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);

    final zips = await _picking([
      PlatformFile(name: 'takeout-001.zip', size: 3, bytes: bytes),
    ]).pickZips();

    expect(zips, [(name: 'takeout-001.zip', bytes: bytes)]);
  });

  test('is null when cancelled', () async {
    expect(await _picking(null).pickZips(), isNull);
  });

  test('a picked file that could not be read is rejected, by name', () async {
    await expectLater(
      _picking([PlatformFile(name: 'takeout-001.zip', size: 1)]).pickZips(),
      throwsA(
        isA<TakeoutImportException>().having(
          (e) => e.message,
          'message',
          contains('"takeout-001.zip"'),
        ),
      ),
    );
  });
}
