import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import 'package:youtube_takeout_manager/src/storage/storage_migration.dart';
import 'package:youtube_takeout_manager/src/storage/storage_service.dart';

/// Fails every write, as a full disk would.
class _Failing extends MemoryEntryStore {
  @override
  Future<void> putAll(String box, Map<String, String> entries) =>
      throw StateError('disk full');
}

/// Keeps only the first entry of each write.
class _Lossy extends MemoryEntryStore {
  @override
  Future<void> putAll(String box, Map<String, String> entries) =>
      super.putAll(box, Map.fromEntries(entries.entries.take(1)));
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'flutter.cached_video_metadata': jsonEncode({
        'v1': {'videoId': 'v1', 'channelId': 'UCa'},
        'v2': {'videoId': 'v2', 'channelId': 'UCb'},
      }),
      'flutter.video_not_found_ids': ['gone1', 'gone2'],
      'flutter.channel_thumbnails_not_found': jsonEncode(['UCx']),
      'flutter.search_scope': 'everything',
    }),
  );

  test(
    'moves each blob into its box, an entry per item, and removes it',
    () async {
      final kv = KvStorageService();
      final store = MemoryEntryStore();

      await migrateLegacyBlobs(kv, store);

      final videos = await store.loadAll(EntryBoxes.videos);
      expect(videos.keys, {'v1', 'v2'});
      expect(jsonDecode(videos['v1']!), {'videoId': 'v1', 'channelId': 'UCa'});
      expect((await store.loadAll(EntryBoxes.videosNotFound)).keys, {
        'gone1',
        'gone2',
      });
      expect((await store.loadAll(EntryBoxes.channelPicturesNotFound)).keys, {
        'UCx',
      });
      expect(await kv.getString('cached_video_metadata'), isNull);
      expect(await kv.getStringList('video_not_found_ids'), isNull);
      // Small settings stay where they are.
      expect(await kv.getString('search_scope'), 'everything');
    },
  );

  test('a write that fails leaves the blob for the next launch', () async {
    final kv = KvStorageService();

    await migrateLegacyBlobs(kv, _Failing());

    expect(await kv.getString('cached_video_metadata'), isNotNull);

    final store = MemoryEntryStore();
    await migrateLegacyBlobs(kv, store);
    expect((await store.loadAll(EntryBoxes.videos)).keys, {'v1', 'v2'});
    expect(await kv.getString('cached_video_metadata'), isNull);
  });

  test('entries that do not read back the same leave the blob', () async {
    final kv = KvStorageService();

    await migrateLegacyBlobs(kv, _Lossy());

    expect(await kv.getString('cached_video_metadata'), isNotNull);
  });

  test('a channel keyed by a long name moves into storage and is still '
      'there after reopening', () async {
    final long = 'name:${'日本語のチャンネル名' * 12}';
    SharedPreferences.setMockInitialValues({
      'flutter.channel_categories': jsonEncode({
        long: {'decidedAt': '2026-09-30'},
      }),
    });
    final dir = await Directory.systemTemp.createTemp('migration');
    addTearDown(() => dir.delete(recursive: true));
    final first = StorageService();
    await first.open(dir.path);

    await migrateLegacyBlobs(KvStorageService(), first);
    await first.close();

    final again = StorageService();
    addTearDown(again.close);
    await again.open(dir.path);
    expect((await again.loadAll(EntryBoxes.channelCategories)).keys, [long]);
    expect(await KvStorageService().getString('channel_categories'), isNull);
  });

  test('once done, running again changes nothing', () async {
    final kv = KvStorageService();
    final store = MemoryEntryStore();
    await migrateLegacyBlobs(kv, store);
    final before = {
      for (final box in EntryBoxes.all) box: await store.loadAll(box),
    };

    await migrateLegacyBlobs(kv, store);

    expect({
      for (final box in EntryBoxes.all) box: await store.loadAll(box),
    }, before);
  });
}
