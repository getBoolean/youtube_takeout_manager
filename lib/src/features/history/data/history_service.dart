import 'dart:async';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import '../domain/history_search.dart';
import '../domain/history_wire.dart';
import '../domain/loaded_history.dart';
import '../domain/watch_filters.dart';
import 'history_csv_codec.dart';
import 'history_service.activator.g.dart';

part 'history_service.worker.g.dart';

/// Keeps the loaded watch and search history off the UI thread, and does
/// what takes going through all of it there: loading, searching, counting
/// and picking the videos told to AI. Run as a worker, an isolate on native
/// and a Web Worker on the web; what it answers is in the shape of
/// `history_wire.dart`. Nothing it imports may import Flutter: on the web
/// it's compiled on its own.
@SquadronService(
  baseUrl: '~/workers',
  targetPlatform: TargetPlatform.vm | TargetPlatform.web,
)
base class HistoryService {
  LoadedHistory? _loaded;

  /// The videos known to be Shorts by their format.
  Set<String> _shortVideos = const {};

  /// Which of the loaded history's watched videos are Shorts, by their
  /// link or their format; worked out when first needed.
  WatchMask? _shortWatches;

  List<Object?>? _picks;

  LoadedHistory get _history =>
      _loaded ?? (throw StateError('No history was loaded.'));

  /// Reads the saved history [files] and keeps it, in place of any loaded
  /// before; answers with what showing it needs.
  @SquadronMethod()
  Future<List<Object?>> load(Map<String, Uint8List> files) async {
    final loaded = loadSavedHistory(files);
    _loaded = loaded;
    _shortWatches = null;
    _picks = null;
    return HistoryRows.of(loaded).toWire();
  }

  /// What the history shows for [query] (a [HistoryQuery] on the wire),
  /// as [HistoryMatches] carrying [generation].
  @SquadronMethod()
  Future<List<Object?>> search(List<Object?> query, int generation) async {
    final loaded = _history;
    final asked = HistoryQuery.fromWire(query);
    final filters = (
      query: asked.query,
      removedOnly: asked.removedOnly,
      shorts: asked.shorts,
      shortWatches: asked.shorts == ShowFilter.all ? null : _shorts(loaded),
      music: asked.music,
      channels: switch (asked.channelMask) {
        final mask? => ChannelMask(mask),
        null => null,
      },
    );
    final results = isUnfiltered(filters)
        ? defaultResults(loaded)
        : searchHistory(loaded, filters);
    return HistoryMatches.of(results, generation: generation).toWire();
  }

  /// Which videos are Shorts by their format, as their IDs, for this
  /// history and any loaded after it; answers how many watched videos are
  /// Shorts now.
  @SquadronMethod()
  Future<int> setShortVideos(List<String> videoIds) async {
    _shortVideos = videoIds.toSet();
    _shortWatches = null;
    return switch (_loaded) {
      final loaded? => _shorts(loaded).count,
      null => 0,
    };
  }

  /// How many videos were watched from each watched channel, in the
  /// loaded history's order, of the kinds the [ShowFilter] indices [shorts]
  /// and [music] show.
  @SquadronMethod()
  Future<Int32List> channelWatchCounts(int shorts, int music) async {
    final loaded = _history;
    final shortsShown = ShowFilter.values[shorts];
    return Int32List.fromList(
      countChannelWatches(
        loaded,
        shorts: shortsShown,
        shortWatches: shortsShown == ShowFilter.all ? null : _shorts(loaded),
        music: ShowFilter.values[music],
      ),
    );
  }

  /// The videos to tell AI about for each watched channel, on the wire.
  @SquadronMethod()
  Future<List<Object?>> promptPicks() async =>
      _picks ??= promptPicksToWire(pickPromptVideos(_history));

  WatchMask _shorts(LoadedHistory loaded) => _shortWatches ??= () {
    final watches = loaded.history.watches;
    final flags = Uint8List(watches.length);
    for (final (i, watch) in watches.indexed) {
      if (watch.isShort || _shortVideos.contains(watch.videoId)) flags[i] = 1;
    }
    return WatchMask(flags);
  }();
}
