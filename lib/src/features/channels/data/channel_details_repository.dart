import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import '../domain/channel_details.dart';

part 'channel_details_repository.g.dart';

@Riverpod(keepAlive: true)
ChannelDetailsRepository channelDetailsRepository(Ref ref) =>
    ChannelDetailsRepository(ref.watch(entryStoreProvider));

/// Keeps channels' topics and descriptions on this device, so they aren't
/// asked for again.
class ChannelDetailsRepository {
  final EntryBox<ChannelDetails> _details;

  ChannelDetailsRepository(EntryStore store)
    : _details = EntryBox(
        store,
        EntryBoxes.channelDetails,
        encode: (details) => details.toJson(),
        decode: (json) =>
            ChannelDetails.fromJson(json! as Map<String, dynamic>),
      );

  /// Entries that can't be read are skipped, keeping the rest.
  Future<Map<String, ChannelDetails>> load() => _details.load();

  Future<void> save(Map<String, ChannelDetails> details) =>
      _details.save(details);

  Future<void> clear() => _details.clear();
}
