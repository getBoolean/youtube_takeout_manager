// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'history_service.dart';

// **************************************************************************
// Generator: WorkerGenerator 9.3.2 (Squadron 7.4.4)
// **************************************************************************

// dart format width=80
/// Command ids used in operations map
const int _$channelWatchCountsId = 1;
const int _$loadId = 2;
const int _$promptPicksId = 3;
const int _$searchId = 4;
const int _$setShortVideosId = 5;

/// WorkerService operations for HistoryService
extension on HistoryService {
  OperationsMap _$getOperations() => OperationsMap({
    _$channelWatchCountsId: ($req) async {
      final Int32List $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await channelWatchCounts(
          $dsr.$0($req.args[0]),
          $dsr.$0($req.args[1]),
        );
      } finally {}
      return $res;
    },
    _$loadId: ($req) async {
      final List<Object?> $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await load($dsr.$3($req.args[0]));
      } finally {}
      return $res;
    },
    _$promptPicksId: ($req) => promptPicks(),
    _$searchId: ($req) async {
      final List<Object?> $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await search($dsr.$5($req.args[0]), $dsr.$0($req.args[1]));
      } finally {}
      return $res;
    },
    _$setShortVideosId: ($req) async {
      final int $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await setShortVideos($dsr.$6($req.args[0]));
      } finally {}
      return $res;
    },
  });
}

/// Invoker for HistoryService, implements the public interface to invoke the
/// remote service.
base mixin _$HistoryService$Invoker on Invoker implements HistoryService {
  @override
  Future<Int32List> channelWatchCounts(int shorts, int music) async {
    final dynamic $res = await send(
      _$channelWatchCountsId,
      args: [shorts, music],
    );
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$7($res);
    } finally {}
  }

  @override
  Future<List<Object?>> load(Map<String, Uint8List> files) async {
    final dynamic $res = await send(_$loadId, args: [files]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$5($res);
    } finally {}
  }

  @override
  Future<List<Object?>> promptPicks() async {
    final dynamic $res = await send(_$promptPicksId);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$5($res);
    } finally {}
  }

  @override
  Future<List<Object?>> search(List<Object?> query, int generation) async {
    final dynamic $res = await send(_$searchId, args: [query, generation]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$5($res);
    } finally {}
  }

  @override
  Future<int> setShortVideos(List<String> videoIds) async {
    final dynamic $res = await send(_$setShortVideosId, args: [videoIds]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$0($res);
    } finally {}
  }
}

/// Facade for HistoryService, implements other details of the service unrelated to
/// invoking the remote service.
base mixin _$HistoryService$Facade implements HistoryService {
  @override
  WatchMask _shorts(LoadedHistory loaded) => throw UnimplementedError();

  @override
  // ignore: unused_element
  LoadedHistory? get _loaded => throw UnimplementedError();

  @override
  // ignore: unused_element
  Set<String> get _shortVideos => throw UnimplementedError();

  @override
  // ignore: unused_element
  WatchMask? get _shortWatches => throw UnimplementedError();

  @override
  // ignore: unused_element
  List<Object?>? get _picks => throw UnimplementedError();

  @override
  // ignore: unused_element
  LoadedHistory get _history => throw UnimplementedError();

  @override
  // ignore: unused_element
  set _loaded(void $value) => throw UnimplementedError();

  @override
  // ignore: unused_element
  set _shortVideos(void $value) => throw UnimplementedError();

  @override
  // ignore: unused_element
  set _shortWatches(void $value) => throw UnimplementedError();

  @override
  // ignore: unused_element
  set _picks(void $value) => throw UnimplementedError();
}

/// WorkerClient for HistoryService
final class $HistoryService$Client extends WorkerClient
    with _$HistoryService$Invoker, _$HistoryService$Facade
    implements HistoryService {
  $HistoryService$Client(PlatformChannel channelInfo)
    : super(Channel.deserialize(channelInfo)!);
}

/// Local worker extension for HistoryService
extension $HistoryServiceLocalWorkerExt on HistoryService {
  // Get a fresh local worker instance.
  LocalWorker<HistoryService> getLocalWorker([
    ExceptionManager? exceptionManager,
  ]) => LocalWorker.create(this, _$getOperations(), exceptionManager);
}

/// WorkerService class for HistoryService
base class _$HistoryService$WorkerService extends HistoryService
    implements WorkerService {
  _$HistoryService$WorkerService() : super();

  @override
  OperationsMap get operations => _$getOperations();
}

/// Service initializer for HistoryService
WorkerService $HistoryServiceInitializer(WorkerRequest $req) =>
    _$HistoryService$WorkerService();

/// Worker for HistoryService
base class HistoryServiceWorker extends Worker
    with _$HistoryService$Invoker, _$HistoryService$Facade
    implements HistoryService {
  // ignore: use_super_parameters
  HistoryServiceWorker({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $HistoryServiceActivator(Squadron.platformType),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  HistoryServiceWorker.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $HistoryServiceActivator(SquadronPlatformType.vm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  HistoryServiceWorker.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $HistoryServiceActivator(SquadronPlatformType.js),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  HistoryServiceWorker.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $HistoryServiceActivator(SquadronPlatformType.wasm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  @override
  List? getStartArgs() => null;
}

/// Worker pool for HistoryService
base class HistoryServiceWorkerPool extends WorkerPool<HistoryServiceWorker>
    with _$HistoryService$Facade
    implements HistoryService {
  // ignore: use_super_parameters
  HistoryServiceWorkerPool({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => HistoryServiceWorker(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  HistoryServiceWorkerPool.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => HistoryServiceWorker.vm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  HistoryServiceWorkerPool.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => HistoryServiceWorker.js(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  // ignore: use_super_parameters
  HistoryServiceWorkerPool.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => HistoryServiceWorker.wasm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  @override
  Future<Int32List> channelWatchCounts(int shorts, int music) =>
      execute((w) => w.channelWatchCounts(shorts, music));

  @override
  Future<List<Object?>> load(Map<String, Uint8List> files) =>
      execute((w) => w.load(files));

  @override
  Future<List<Object?>> promptPicks() => execute((w) => w.promptPicks());

  @override
  Future<List<Object?>> search(List<Object?> query, int generation) =>
      execute((w) => w.search(query, generation));

  @override
  Future<int> setShortVideos(List<String> videoIds) =>
      execute((w) => w.setShortVideos(videoIds));
}

final class _$Deser extends MarshalingContext {
  _$Deser({super.contextAware});
  late final $0 = value<int>();
  late final $1 = value<String>();
  late final $2 = value<Uint8List>();
  late final $3 = map<String, Uint8List>(kcast: $1, vcast: $2);
  late final $4 = value<Object>();
  late final $5 = nlist<Object>($4);
  late final $6 = list<String>($1);
  late final $7 = value<Int32List>();
}
