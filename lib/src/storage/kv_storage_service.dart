import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'kv_storage_service_stub.dart'
    if (dart.library.io) 'kv_storage_service_native.dart'
    if (dart.library.js_interop) 'kv_storage_service_web.dart'
    as platform;

part 'kv_storage_service.g.dart';

@Riverpod(keepAlive: true)
KvStorageService kvStorageService(Ref ref) => KvStorageService();

/// Platform-agnostic key-value storage.
///
/// - Native: delegates to SharedPreferences
/// - Web: uses IndexedDB (with one-time migration from localStorage)
abstract class KvStorageService {
  factory KvStorageService() = platform.KvStorageServiceImpl;

  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<bool?> getBoolean(String key);
  Future<void> setBoolean(String key, bool value);
  Future<void> remove(String key);
}
