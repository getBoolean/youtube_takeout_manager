import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

part 'takeout_account_repository.g.dart';

@Riverpod(keepAlive: true)
TakeoutAccountRepository takeoutAccountRepository(Ref ref) =>
    TakeoutAccountRepository(ref.watch(kvStorageServiceProvider));

/// Remembers which account's saved takeout data the app shows.
class TakeoutAccountRepository {
  static const _activeAccountKey = 'active_takeout_account';

  final KvStorageService _kv;

  TakeoutAccountRepository(this._kv);

  Future<String?> loadActiveAccountId() => _kv.getString(_activeAccountKey);

  Future<void> saveActiveAccountId(String accountId) =>
      _kv.setString(_activeAccountKey, accountId);
}
