import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_service.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('storage'));
  tearDown(() => dir.delete(recursive: true));

  test('keeps entries and images once opened', () async {
    final storage = StorageService();
    addTearDown(storage.close);
    await storage.open(dir.path);

    await storage.putAll(EntryBoxes.videos, {'v1': '1'});
    await storage.writeImage('pic', Uint8List.fromList([7]));

    expect(await storage.loadAll(EntryBoxes.videos), {'v1': '1'});
    expect(await storage.readImage('pic'), [7]);
  });

  test('asked before it is opened, it says so', () async {
    expect(StorageService().loadAll(EntryBoxes.videos), throwsStateError);
  });

  test('runs in a worker of its own', () async {
    final worker = StorageServiceWorker();
    addTearDown(() async {
      await worker.close();
      worker.stop();
    });

    await worker.open(dir.path);
    await worker.putAll(EntryBoxes.videos, {'v1': '1'});

    expect(await worker.loadAll(EntryBoxes.videos), {'v1': '1'});
  });
}
