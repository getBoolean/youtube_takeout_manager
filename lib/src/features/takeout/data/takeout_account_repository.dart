import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

part 'takeout_account_repository.g.dart';

@Riverpod(keepAlive: true)
TakeoutAccountRepository takeoutAccountRepository(Ref ref) =>
    TakeoutAccountRepository(ref.watch(kvStorageServiceProvider));

/// Remembers which saved takeout the app shows, and the channel last viewed
/// in each.
class TakeoutAccountRepository {
  static const _activeAccountKey = 'active_takeout_account';
  static const _viewedChannelKeyPrefix = 'viewed_takeout_channel:';

  final KvStorageService _kv;

  TakeoutAccountRepository(this._kv);

  Future<String?> loadActiveAccountId() => _kv.getString(_activeAccountKey);

  Future<void> saveActiveAccountId(String accountId) =>
      _kv.setString(_activeAccountKey, accountId);

  Future<void> clearActiveAccountId() => _kv.remove(_activeAccountKey);

  Future<String?> loadViewedChannelId(String takeoutId) =>
      _kv.getString('$_viewedChannelKeyPrefix$takeoutId');

  Future<void> saveViewedChannelId(String takeoutId, String channelId) =>
      _kv.setString('$_viewedChannelKeyPrefix$takeoutId', channelId);

  Future<void> clearViewedChannelId(String takeoutId) =>
      _kv.remove('$_viewedChannelKeyPrefix$takeoutId');
}
