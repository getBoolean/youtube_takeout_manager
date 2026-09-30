// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'storage_service.dart';

// **************************************************************************
// Generator: WorkerGenerator 9.3.2 (Squadron 7.4.4)
// **************************************************************************

// dart format width=80
/// Command ids used in operations map
const int _$clearId = 1;
const int _$clearImagesId = 2;
const int _$closeId = 3;
const int _$deleteAllId = 4;
const int _$loadAllId = 5;
const int _$openId = 6;
const int _$putAllId = 7;
const int _$readImageId = 8;
const int _$writeImageId = 9;

/// WorkerService operations for StorageService
extension on StorageService {
  OperationsMap _$getOperations() => OperationsMap({
    _$clearId: ($req) {
      final $dsr = _$Deser(contextAware: false);
      return clear($dsr.$0($req.args[0]));
    },
    _$clearImagesId: ($req) => clearImages(),
    _$closeId: ($req) => close(),
    _$deleteAllId: ($req) {
      final $dsr = _$Deser(contextAware: false);
      return deleteAll($dsr.$0($req.args[0]), $dsr.$1($req.args[1]));
    },
    _$loadAllId: ($req) async {
      final Map<String, String> $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await loadAll($dsr.$0($req.args[0]));
      } finally {}
      return $res;
    },
    _$openId: ($req) {
      final $dsr = _$Deser(contextAware: false);
      return open($dsr.$2($req.args[0]));
    },
    _$putAllId: ($req) {
      final $dsr = _$Deser(contextAware: false);
      return putAll($dsr.$0($req.args[0]), $dsr.$3($req.args[1]));
    },
    _$readImageId: ($req) async {
      final Uint8List? $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await readImage($dsr.$0($req.args[0]));
      } finally {}
      return $res;
    },
    _$writeImageId: ($req) {
      final $dsr = _$Deser(contextAware: false);
      return writeImage($dsr.$0($req.args[0]), $dsr.$4($req.args[1]));
    },
  });
}

/// Invoker for StorageService, implements the public interface to invoke the
/// remote service.
base mixin _$StorageService$Invoker on Invoker implements StorageService {
  @override
  Future<void> clear(String box) => send(_$clearId, args: [box]);

  @override
  Future<void> clearImages() => send(_$clearImagesId);

  @override
  Future<void> close() => send(_$closeId);

  @override
  Future<void> deleteAll(String box, List<String> keys) =>
      send(_$deleteAllId, args: [box, keys]);

  @override
  Future<Map<String, String>> loadAll(String box) async {
    final dynamic $res = await send(_$loadAllId, args: [box]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$3($res);
    } finally {}
  }

  @override
  Future<void> open(String? directory) => send(_$openId, args: [directory]);

  @override
  Future<void> putAll(String box, Map<String, String> entries) =>
      send(_$putAllId, args: [box, entries]);

  @override
  Future<Uint8List?> readImage(String key) async {
    final dynamic $res = await send(_$readImageId, args: [key]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$5($res);
    } finally {}
  }

  @override
  Future<void> writeImage(String key, Uint8List bytes) =>
      send(_$writeImageId, args: [key, bytes]);
}

/// Facade for StorageService, implements other details of the service unrelated to
/// invoking the remote service.
base mixin _$StorageService$Facade implements StorageService {
  @override
  // ignore: unused_element
  StorageBackend? get _backend => throw UnimplementedError();

  @override
  // ignore: unused_element
  StorageBackend get _open => throw UnimplementedError();

  @override
  // ignore: unused_element
  set _backend(void $value) => throw UnimplementedError();
}

/// WorkerClient for StorageService
final class $StorageService$Client extends WorkerClient
    with _$StorageService$Invoker, _$StorageService$Facade
    implements StorageService {
  $StorageService$Client(PlatformChannel channelInfo)
    : super(Channel.deserialize(channelInfo)!);
}

/// Local worker extension for StorageService
extension $StorageServiceLocalWorkerExt on StorageService {
  // Get a fresh local worker instance.
  LocalWorker<StorageService> getLocalWorker([
    ExceptionManager? exceptionManager,
  ]) => LocalWorker.create(this, _$getOperations(), exceptionManager);
}

/// WorkerService class for StorageService
base class _$StorageService$WorkerService extends StorageService
    implements WorkerService {
  _$StorageService$WorkerService() : super();

  @override
  OperationsMap get operations => _$getOperations();
}

/// Service initializer for StorageService
WorkerService $StorageServiceInitializer(WorkerRequest $req) =>
    _$StorageService$WorkerService();

/// Worker for StorageService
base class StorageServiceWorker extends Worker
    with _$StorageService$Invoker, _$StorageService$Facade
    implements StorageService {
  // ignore: use_super_parameters
  StorageServiceWorker({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $StorageServiceActivator(Squadron.platformType),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  StorageServiceWorker.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $StorageServiceActivator(SquadronPlatformType.vm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  StorageServiceWorker.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $StorageServiceActivator(SquadronPlatformType.js),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  StorageServiceWorker.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $StorageServiceActivator(SquadronPlatformType.wasm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  @override
  List? getStartArgs() => null;
}

/// Worker pool for StorageService
base class StorageServiceWorkerPool extends WorkerPool<StorageServiceWorker>
    with _$StorageService$Facade
    implements StorageService {
  // ignore: use_super_parameters
  StorageServiceWorkerPool({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => StorageServiceWorker(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  StorageServiceWorkerPool.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => StorageServiceWorker.vm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  StorageServiceWorkerPool.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => StorageServiceWorker.js(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  StorageServiceWorkerPool.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => StorageServiceWorker.wasm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  @override
  Future<void> clear(String box) => execute((w) => w.clear(box));

  @override
  Future<void> clearImages() => execute((w) => w.clearImages());

  @override
  Future<void> close() => execute((w) => w.close());

  @override
  Future<void> deleteAll(String box, List<String> keys) =>
      execute((w) => w.deleteAll(box, keys));

  @override
  Future<Map<String, String>> loadAll(String box) =>
      execute((w) => w.loadAll(box));

  @override
  Future<void> open(String? directory) => execute((w) => w.open(directory));

  @override
  Future<void> putAll(String box, Map<String, String> entries) =>
      execute((w) => w.putAll(box, entries));

  @override
  Future<Uint8List?> readImage(String key) => execute((w) => w.readImage(key));

  @override
  Future<void> writeImage(String key, Uint8List bytes) =>
      execute((w) => w.writeImage(key, bytes));
}

final class _$Deser extends MarshalingContext {
  _$Deser({super.contextAware});
  late final $0 = value<String>();
  late final $1 = list<String>($0);
  late final $2 = Converter.allowNull($0);
  late final $3 = map<String, String>(kcast: $0, vcast: $0);
  late final $4 = value<Uint8List>();
  late final $5 = Converter.allowNull($4);
}
