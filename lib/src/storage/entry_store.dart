/// The boxes bulk data is kept in, one entry per video or channel.
abstract final class EntryBoxes {
  static const videos = 'videos';
  static const videosNotFound = 'videos_not_found';
  static const videoFormats = 'video_formats';
  static const videoFormatsNotFound = 'video_formats_not_found';
  static const channelPictures = 'channel_pictures';
  static const channelPicturesNotFound = 'channel_pictures_not_found';
  static const channelDetails = 'channel_details';
  static const channelCategories = 'channel_categories';
  static const customSubCategories = 'custom_sub_categories';
  static const tags = 'tags';

  /// Every box of entries, for storage that must create them up front.
  static const all = [
    videos,
    videosNotFound,
    videoFormats,
    videoFormatsNotFound,
    channelPictures,
    channelPicturesNotFound,
    channelDetails,
    channelCategories,
    customSubCategories,
    tags,
  ];
}

/// Keeps bulk data as string entries in named boxes, each entry written on
/// its own, so saving a few never rewrites the rest.
abstract interface class EntryStore {
  /// Every entry of [box], by key; none for a box never written.
  Future<Map<String, String>> loadAll(String box);

  /// Writes [entries] into [box], replacing any with the same keys.
  Future<void> putAll(String box, Map<String, String> entries);

  Future<void> deleteAll(String box, List<String> keys);

  Future<void> clear(String box);
}

/// An [EntryStore] in memory over [boxes], which it shares, so stores made
/// over the same boxes see each other's writes: for tests.
class MemoryEntryStore implements EntryStore {
  final Map<String, Map<String, String>> boxes;

  MemoryEntryStore([Map<String, Map<String, String>>? boxes])
    : boxes = boxes ?? {};

  @override
  Future<Map<String, String>> loadAll(String box) async => {...?boxes[box]};

  @override
  Future<void> putAll(String box, Map<String, String> entries) async =>
      boxes.putIfAbsent(box, () => {}).addAll(entries);

  @override
  Future<void> deleteAll(String box, List<String> keys) async {
    final entries = boxes[box];
    if (entries == null) return;
    for (final key in keys) {
      entries.remove(key);
    }
  }

  @override
  Future<void> clear(String box) async => boxes.remove(box);
}
