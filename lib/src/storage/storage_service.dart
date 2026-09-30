import 'dart:async';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';

import 'entry_store.dart';
import 'storage_backend.dart';
import 'storage_service.activator.g.dart';

part 'storage_service.worker.g.dart';

/// Keeps the app's bulk data, entries in boxes and cached images, off the
/// UI thread: run as a worker, an isolate on native and a Web Worker on
/// the web. Nothing it imports may import Flutter: on the web it's compiled
/// on its own.
@SquadronService(
  baseUrl: '~/workers',
  targetPlatform: TargetPlatform.vm | TargetPlatform.web,
)
base class StorageService implements EntryStore {
  StorageBackend? _backend;

  StorageBackend get _open =>
      _backend ?? (throw StateError('Storage was not opened.'));

  /// Opens storage in [directory] on native platforms, or IndexedDB on the
  /// web (where [directory] is null).
  @SquadronMethod()
  Future<void> open(String? directory) async {
    _backend ??= await openStorageBackend(directory);
  }

  @override
  @SquadronMethod()
  Future<Map<String, String>> loadAll(String box) async => _open.loadAll(box);

  @override
  @SquadronMethod()
  Future<void> putAll(String box, Map<String, String> entries) async =>
      _open.putAll(box, entries);

  @override
  @SquadronMethod()
  Future<void> deleteAll(String box, List<String> keys) async =>
      _open.deleteAll(box, keys);

  @override
  @SquadronMethod()
  Future<void> clear(String box) async => _open.clear(box);

  @SquadronMethod()
  Future<Uint8List?> readImage(String key) async => _open.readImage(key);

  @SquadronMethod()
  Future<void> writeImage(String key, Uint8List bytes) async =>
      _open.writeImage(key, bytes);

  @SquadronMethod()
  Future<void> clearImages() async => _open.clearImages();

  @SquadronMethod()
  Future<void> close() async {
    await _backend?.close();
    _backend = null;
  }
}
