import 'dart:convert';

import 'entry_store.dart';
import 'kv_storage_service.dart';

/// How a blob kept whole in key-value storage was shaped.
enum LegacyShape {
  /// A JSON object of items by key.
  jsonMap,

  /// A string list of IDs.
  stringList,

  /// A JSON array of IDs, kept as a string.
  jsonList,
}

/// A blob from before entries: its key-value key, the box its items move
/// to, and its shape.
typedef LegacyBlob = ({String key, String box, LegacyShape shape});

/// Every blob that moves into a box.
const legacyBlobs = <LegacyBlob>[
  (
    key: 'cached_video_metadata',
    box: EntryBoxes.videos,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'video_not_found_ids',
    box: EntryBoxes.videosNotFound,
    shape: LegacyShape.stringList,
  ),
  (
    key: 'video_formats',
    box: EntryBoxes.videoFormats,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'video_formats_not_found',
    box: EntryBoxes.videoFormatsNotFound,
    shape: LegacyShape.stringList,
  ),
  (
    key: 'cached_channel_thumbnails',
    box: EntryBoxes.channelPictures,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'channel_thumbnails_not_found',
    box: EntryBoxes.channelPicturesNotFound,
    shape: LegacyShape.jsonList,
  ),
  (
    key: 'channel_details',
    box: EntryBoxes.channelDetails,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'channel_categories',
    box: EntryBoxes.channelCategories,
    shape: LegacyShape.jsonMap,
  ),
  (
    key: 'custom_category_children',
    box: EntryBoxes.customSubCategories,
    shape: LegacyShape.jsonMap,
  ),
];

/// Moves each of [blobs] from [kv] into its box of [store], an entry per
/// item. A blob is removed only once its entries read back the same; a
/// failure anywhere leaves it for the next launch. Never throws.
Future<void> migrateLegacyBlobs(
  KvStorageService kv,
  EntryStore store, {
  List<LegacyBlob> blobs = legacyBlobs,
}) async {
  for (final blob in blobs) {
    try {
      final entries = await _read(kv, blob);
      if (entries == null) continue;
      await store.putAll(blob.box, entries);
      final back = await store.loadAll(blob.box);
      if (entries.entries.every((e) => back[e.key] == e.value)) {
        await kv.remove(blob.key);
      }
    } on Object {
      // Left for the next launch.
    }
  }
}

/// [blob]'s items as entries (each value as JSON, IDs as `1`), or null
/// when there's no such blob.
Future<Map<String, String>?> _read(KvStorageService kv, LegacyBlob blob) async {
  switch (blob.shape) {
    case LegacyShape.stringList:
      final ids = await kv.getStringList(blob.key);
      return ids == null ? null : {for (final id in ids) id: '1'};
    case LegacyShape.jsonList:
      final json = await kv.getString(blob.key);
      if (json == null) return null;
      return {
        for (final id
            in (jsonDecode(json) as List<dynamic>).whereType<String>())
          id: '1',
      };
    case LegacyShape.jsonMap:
      final json = await kv.getString(blob.key);
      if (json == null) return null;
      return {
        for (final MapEntry(:key, :value)
            in (jsonDecode(json) as Map<String, dynamic>).entries)
          key: jsonEncode(value),
      };
  }
}
