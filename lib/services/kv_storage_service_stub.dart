import 'kv_storage_service.dart';

class KvStorageServiceImpl implements KvStorageService {
  KvStorageServiceImpl() {
    throw UnsupportedError(
      'No platform implementation for KvStorageService',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
