import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:squadron/squadron.dart';

import '../domain/history_wire.dart';
import '../domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/utils/worker_death/worker_death.dart';
import 'history_service.dart';

part 'history_engine.g.dart';

/// Where the loaded history is kept, searched and counted: the History
/// worker, or in-process in tests. Answers come typed, from the wire.
abstract interface class HistoryEngine {
  /// Reads the saved history [files], in place of any loaded before.
  Future<HistoryRows> load(Map<String, Uint8List> files);

  /// What the history shows for [query], carrying [generation].
  Future<HistoryMatches> search(HistoryQuery query, int generation);

  /// Which videos are Shorts by their format; answers how many watched
  /// videos are Shorts now.
  Future<int> setShortVideos(List<String> videoIds);

  /// How many videos were watched from each watched channel, in the loaded
  /// history's order, of the kinds [shorts] and [music] show.
  Future<Int32List> channelWatchCounts({
    ShowFilter shorts = ShowFilter.all,
    ShowFilter music = ShowFilter.all,
  });

  Future<void> stop();
}

/// The History worker stopped, and stopped again once replaced.
class HistoryWorkerDied implements Exception {
  const HistoryWorkerDied();

  @override
  String toString() => 'The History worker stopped working.';
}

/// Runs the history on a worker it starts on first use. A call that fails
/// is the caller's to handle, on the same worker. A worker that died is
/// replaced, the history last loaded into it loaded again, with the Shorts
/// it was told of, and every call under way when it died is made again on
/// the replacement; when that one dies too, or can't be started, the call
/// throws [HistoryWorkerDied], and the next call starts afresh. Workers are
/// started by [startHistoryWorker], so one that dies fails its calls rather
/// than leaving them waiting.
class WorkerHistoryEngine implements HistoryEngine {
  final Future<HistoryService> Function() _start;
  final bool Function(HistoryService service) _isDead;
  Future<HistoryService>? _service;

  /// Raised when a dead worker is replaced, so a call that failed on it
  /// knows to run on the replacement rather than replace it again.
  var _generation = 0;

  /// What was last loaded, and the Shorts last told of, for a replacement.
  Map<String, Uint8List>? _files;
  List<String>? _shortVideos;

  WorkerHistoryEngine(
    this._start, {
    bool Function(HistoryService service)? isDead,
  }) : _isDead = isDead ?? _workerDied;

  /// Whether [service]'s worker thread is gone.
  static bool _workerDied(HistoryService service) => switch (service) {
    final Worker worker => worker.isStopped || !worker.isConnected,
    _ => false,
  };

  /// Makes [call] on the worker, and once more on a replacement when the
  /// worker died; a call that [loads] is itself what loads the replacement.
  Future<T> _run<T>(
    Future<T> Function(HistoryService history) call, {
    bool loads = false,
  }) async {
    for (var attempt = 1; ; attempt++) {
      final generation = _generation;
      HistoryService? service;
      try {
        service = await _current(loads: loads);
        return await call(service);
      } on SquadronException catch (e) {
        // A call's own failure, on a worker still running, is the caller's.
        if (service != null && !_isDead(service) && !_closed(e)) rethrow;
        // The first call to find it dead replaces it for every call under
        // way on it.
        if (generation == _generation) _replace(service);
        if (attempt == 2) throw const HistoryWorkerDied();
      }
    }
  }

  /// Whether [e] says the worker's channel closed, as when its thread died.
  static bool _closed(SquadronException e) =>
      e is SquadronError && e.message.contains('Channel is closed');

  void _replace(HistoryService? dead) {
    _generation++;
    _service = null;
    if (dead != null) unawaited(_retire(dead));
  }

  /// The worker, started with the history last loaded, unless the call
  /// about to be made [loads] one, when there's none, or when the last
  /// start failed.
  Future<HistoryService> _current({required bool loads}) {
    if (_service case final service?) return service;
    late final Future<HistoryService> started;
    started =
        () async {
          final service = await _start();
          if (_files case final files? when !loads) await service.load(files);
          if (_shortVideos case final ids?) await service.setShortVideos(ids);
          return service;
        }().onError<Object>((error, stackTrace) {
          if (identical(_service, started)) _service = null;
          Error.throwWithStackTrace(error, stackTrace);
        });
    return _service = started;
  }

  @override
  Future<HistoryRows> load(Map<String, Uint8List> files) async {
    // Kept first: a worker replaced after the load loads them.
    _files = files;
    return HistoryRows.fromWire(await _run((h) => h.load(files), loads: true));
  }

  @override
  Future<HistoryMatches> search(HistoryQuery query, int generation) async =>
      HistoryMatches.fromWire(
        await _run((h) => h.search(query.toWire(), generation)),
      );

  @override
  Future<int> setShortVideos(List<String> videoIds) {
    _shortVideos = videoIds;
    return _run((h) => h.setShortVideos(videoIds));
  }

  @override
  Future<Int32List> channelWatchCounts({
    ShowFilter shorts = ShowFilter.all,
    ShowFilter music = ShowFilter.all,
  }) => _run((h) => h.channelWatchCounts(shorts.index, music.index));

  @override
  Future<void> stop() async {
    final service = _service;
    _service = null;
    if (service == null) return;
    try {
      await _retire(await service);
    } on Object {
      // It never started.
    }
  }

  static Future<void> _retire(HistoryService service) async {
    if (service case final Worker worker) worker.stop();
  }
}

/// The history kept in-process, through the same wire as the worker's:
/// for tests.
class LocalHistoryEngine extends WorkerHistoryEngine {
  LocalHistoryEngine() : super(() async => HistoryService());
}

/// Starts a History worker that's stopped, failing the calls under way, as
/// soon as its thread dies; [threadHook] is given its thread too.
HistoryServiceWorker startHistoryWorker({PlatformThreadHook? threadHook}) =>
    terminatedWhenItDies(
      (hook) => HistoryServiceWorker(threadHook: hook),
      threadHook: threadHook,
    );

var _local = false;

/// Tests: the history is kept in-process from now on.
/// `flutter_test_config.dart` sets it.
@visibleForTesting
void setLocalHistoryEngine() => _local = true;

/// Where the loaded history is kept: the History worker, started on first
/// use, or in-process in tests.
@Riverpod(keepAlive: true)
HistoryEngine historyEngine(Ref ref) {
  final engine = _local
      ? LocalHistoryEngine()
      : WorkerHistoryEngine(() async => startHistoryWorker());
  ref.onDispose(engine.stop);
  return engine;
}
