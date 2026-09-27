import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_request.dart';

void main() {
  /// Picks [files], recording whether their contents were asked for.
  (ZipPickerRepository, List<bool>) picking(
    List<PlatformFile>? files, {
    required bool inMemory,
  }) {
    final dataAsked = <bool>[];
    final repository = ZipPickerRepository(
      inMemory: inMemory,
      pickFiles: ({required withData}) async {
        dataAsked.add(withData);
        return files == null ? null : FilePickerResult(files);
      },
    );
    return (repository, dataAsked);
  }

  group('on desktop', () {
    test('keeps where each zip is, without reading it', () async {
      final (repository, dataAsked) = picking([
        PlatformFile(
          name: 'takeout-001.zip',
          path: r'B:\Downloads\takeout-001.zip',
          size: 51 << 30,
        ),
      ], inMemory: false);

      final zips = await repository.pickZips();

      expect(dataAsked, [false]);
      expect(zips, [
        isA<PickedZipFile>()
            .having((z) => z.name, 'name', 'takeout-001.zip')
            .having((z) => z.path, 'path', r'B:\Downloads\takeout-001.zip'),
      ]);
    });

    test('a picked file without a path is rejected, by name', () async {
      final (repository, _) = picking([
        PlatformFile(name: 'takeout-001.zip', size: 1),
      ], inMemory: false);

      await expectLater(repository.pickZips(), _rejects('takeout-001.zip'));
    });
  });

  group('on web', () {
    test('reads the picked zips', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final (repository, dataAsked) = picking([
        PlatformFile(name: 'takeout-001.zip', size: 3, bytes: bytes),
      ], inMemory: true);

      final zips = await repository.pickZips();

      expect(dataAsked, [true]);
      expect(zips, [
        isA<PickedZipBytes>()
            .having((z) => z.name, 'name', 'takeout-001.zip')
            .having((z) => z.bytes, 'bytes', bytes),
      ]);
    });

    test('a picked file that could not be read is rejected, by name', () async {
      final (repository, _) = picking([
        PlatformFile(name: 'takeout-001.zip', size: 1),
      ], inMemory: true);

      await expectLater(repository.pickZips(), _rejects('takeout-001.zip'));
    });
  });

  test('is null when cancelled', () async {
    final (repository, _) = picking(null, inMemory: false);
    expect(await repository.pickZips(), isNull);
  });
}

Matcher _rejects(String name) => throwsA(
  isA<TakeoutImportException>().having(
    (e) => e.message,
    'message',
    contains('"$name"'),
  ),
);
