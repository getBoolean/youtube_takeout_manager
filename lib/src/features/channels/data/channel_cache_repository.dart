import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';

part 'channel_cache_repository.g.dart';

@Riverpod(keepAlive: true)
ChannelCacheRepository channelCacheRepository(Ref ref) =>
    ChannelCacheRepository(ref.watch(entryStoreProvider));

/// Persists channel thumbnail URLs to local storage
/// so they survive app restarts and avoid redundant API calls.
class ChannelCacheRepository {
  final EntryBox<String> _pictures;
  final EntrySet _notFound;

  ChannelCacheRepository(EntryStore store)
    : _pictures = EntryBox(
        store,
        EntryBoxes.channelPictures,
        encode: (url) => url,
        decode: (json) => json! as String,
      ),
      _notFound = EntrySet(store, EntryBoxes.channelPicturesNotFound);

  Future<Map<String, String>> loadCachedThumbnails() => _pictures.load();

  Future<void> saveThumbnails(Map<String, String> thumbnails) =>
      _pictures.save(thumbnails);

  /// Channels YouTube had no picture for, e.g. since deleted, so they
  /// aren't asked for again.
  Future<Set<String>> loadNotFoundIds() => _notFound.load();

  Future<void> saveNotFoundIds(Set<String> ids) => _notFound.save(ids);

  /// Forgets the pictures and the channels that had none.
  Future<void> clearThumbnails() async {
    await _pictures.clear();
    await _notFound.clear();
  }
}
