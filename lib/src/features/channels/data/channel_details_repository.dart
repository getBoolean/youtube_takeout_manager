import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/channel_details.dart';

part 'channel_details_repository.g.dart';

@Riverpod(keepAlive: true)
ChannelDetailsRepository channelDetailsRepository(Ref ref) =>
    ChannelDetailsRepository(ref.watch(kvStorageServiceProvider));

const _detailsKey = 'channel_details';

/// Keeps channels' topics and descriptions on this device, so they aren't
/// asked for again.
class ChannelDetailsRepository {
  final KvStorageService _kv;

  ChannelDetailsRepository(this._kv);

  /// Entries that can't be read are skipped, keeping the rest.
  Future<Map<String, ChannelDetails>> load() async {
    final json = await _kv.getString(_detailsKey);
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return {
      for (final MapEntry(:key, :value) in map.entries) key: ?_read(value),
    };
  }

  static ChannelDetails? _read(Object? value) {
    try {
      return ChannelDetails.fromJson(value! as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> save(Map<String, ChannelDetails> details) => _kv.setString(
    _detailsKey,
    jsonEncode({
      for (final MapEntry(:key, :value) in details.entries) key: value.toJson(),
    }),
  );

  Future<void> clear() => _kv.remove(_detailsKey);
}
