import 'storage_backend.dart';

/// No storage where there are neither files nor IndexedDB.
Future<StorageBackend> openStorageBackend(String? directory) =>
    throw UnsupportedError('No storage on this platform.');
