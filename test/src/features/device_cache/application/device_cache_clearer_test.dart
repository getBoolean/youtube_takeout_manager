import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/device_cache/application/device_cache_clearer.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final kept = {
    EntryBoxes.videos: {'v1': '{"videoId":"v1","channelId":"UCa"}'},
    EntryBoxes.videoFormats: {'v1': '[40,2]'},
    EntryBoxes.channelPictures: {'UCa': '"https://yt3.example/UCa"'},
    EntryBoxes.channelDetails: {'UCa': '{"topicUrls":[]}'},
    EntryBoxes.channelCategories: {'UCa': '{"decidedAt":"2026-09-30"}'},
  };

  ProviderContainer container() {
    setMockStorage(entries: kept);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('clears the pictures and thumbnails kept on the device', () async {
    final c = container();
    final images = c.read(imageBytesCacheProvider)!;
    await images.write('pic', Uint8List.fromList([1]));

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(await images.read('pic'), isNull);
  });

  test('keeps video details, lengths and shapes, picture links, topics and '
      'categories', () async {
    final c = container();

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(mockStorageEntries, kept);
  });

  test('forgets the pictures held in memory', () async {
    final c = container();
    final memory = PaintingBinding.instance.imageCache;
    memory.putIfAbsent(
      'held',
      () => OneFrameImageStreamCompleter(Future.any([])),
    );
    expect(memory.pendingImageCount + memory.currentSize, greaterThan(0));

    await c.read(deviceCacheClearerProvider.notifier).clear();

    expect(memory.pendingImageCount + memory.currentSize, 0);
  });
}
