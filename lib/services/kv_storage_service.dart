import 'kv_storage_service_stub.dart'
    if (dart.library.io) 'kv_storage_service_native.dart'
    if (dart.library.js_interop) 'kv_storage_service_web.dart'
    as platform;

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
  Future<void> remove(String key);
}
