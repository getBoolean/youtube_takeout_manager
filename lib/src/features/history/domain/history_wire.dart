import 'dart:collection';
import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'channel_groups.dart';
import 'history_days.dart';
import 'history_search.dart';
import 'loaded_history.dart';
import 'search_entry.dart';
import 'takeout_history.dart';
import 'watch_entry.dart';
import 'watch_filters.dart';
import 'watched_channels.dart';

// What the History worker and the screen send each other: typed arrays,
// strings, numbers and lists of them only, so they cross to a Web Worker
// as they are. Nothing here may import Flutter.

double _ms(DateTime? time) =>
    time == null ? double.nan : time.millisecondsSinceEpoch.toDouble();

DateTime? _time(double ms) => ms.isNaN
    ? null
    : DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true);

Int32List _ints(Object? wire) => wire is Int32List
    ? wire
    : Int32List.fromList([for (final n in wire! as List) (n as num).toInt()]);

Float64List _doubles(Object? wire) => wire is Float64List
    ? wire
    : Float64List.fromList([
        for (final n in wire! as List) (n as num).toDouble(),
      ]);

Uint8List _bytes(Object? wire) => wire is Uint8List
    ? wire
    : Uint8List.fromList([for (final n in wire! as List) (n as num).toInt()]);

List<String?> _maybeStrings(Object? wire) =>
    List<String?>.from(wire! as List, growable: false);

List<String> _strings(Object? wire) =>
    List<String>.from(wire! as List, growable: false);

/// A list whose items are made from [_make] when first read, then kept.
class _Lazy<T> extends ListBase<T> {
  final List<T?> _made;
  final T Function(int i) _make;

  _Lazy(int length, this._make) : _made = List.filled(length, null);

  @override
  int get length => _made.length;

  @override
  set length(int _) => throw UnsupportedError('Fixed length');

  @override
  T operator [](int i) => _made[i] ??= _make(i);

  @override
  void operator []=(int i, T value) => throw UnsupportedError('Read only');
}

/// A loaded history as the screen needs it, in columns: each watched
/// video's and search's fields, and what was worked out from them while it
/// loaded, so the screen never works through every entry itself.
class HistoryRows {
  final Float64List watchTimes;
  final Uint8List watchKinds;
  final Uint8List watchMusic;
  final Float64List watchRemovedAt;
  final List<String?> watchTitles;
  final List<String> watchUrls;
  final List<String?> watchChannelTitles;
  final List<String?> watchChannelUrls;

  final Float64List searchTimes;
  final Uint8List searchMusic;
  final Float64List searchRemovedAt;
  final List<String> searchQueries;

  /// When the watches and the searches were exported; NaN for never.
  final Float64List snapshots;

  final Int32List watchDayKeys;
  final Int32List searchDayKeys;
  final Int32List watchChannelIndex;

  /// The watched channels, the most watched first.
  final List<String?> channelIds;
  final List<String> channelTitles;
  final List<String?> channelUrls;
  final Int32List channelCounts;
  final Float64List channelLastWatched;

  final List<String> recentChannelIds;

  /// How many watches and searches were removed, how many watches were
  /// Shorts and how many on YouTube Music.
  final Int32List counts;

  /// Everything, by day, month and channel.
  final HistoryMatches all;

  HistoryRows._({
    required this.watchTimes,
    required this.watchKinds,
    required this.watchMusic,
    required this.watchRemovedAt,
    required this.watchTitles,
    required this.watchUrls,
    required this.watchChannelTitles,
    required this.watchChannelUrls,
    required this.searchTimes,
    required this.searchMusic,
    required this.searchRemovedAt,
    required this.searchQueries,
    required this.snapshots,
    required this.watchDayKeys,
    required this.searchDayKeys,
    required this.watchChannelIndex,
    required this.channelIds,
    required this.channelTitles,
    required this.channelUrls,
    required this.channelCounts,
    required this.channelLastWatched,
    required this.recentChannelIds,
    required this.counts,
    required this.all,
  });

  factory HistoryRows.of(LoadedHistory loaded) {
    final watches = loaded.history.watches;
    final searches = loaded.history.searches;
    final channels = loaded.watchedChannels;
    return HistoryRows._(
      watchTimes: Float64List.fromList([for (final w in watches) _ms(w.time)]),
      watchKinds: Uint8List.fromList([for (final w in watches) w.kind.index]),
      watchMusic: Uint8List.fromList([
        for (final w in watches) w.music ? 1 : 0,
      ]),
      watchRemovedAt: Float64List.fromList([
        for (final w in watches) _ms(w.removedAt),
      ]),
      watchTitles: [for (final w in watches) w.title],
      watchUrls: [for (final w in watches) w.url],
      watchChannelTitles: [for (final w in watches) w.channelTitle],
      watchChannelUrls: [for (final w in watches) w.channelUrl],
      searchTimes: Float64List.fromList([
        for (final s in searches) _ms(s.time),
      ]),
      searchMusic: Uint8List.fromList([
        for (final s in searches) s.music ? 1 : 0,
      ]),
      searchRemovedAt: Float64List.fromList([
        for (final s in searches) _ms(s.removedAt),
      ]),
      searchQueries: [for (final s in searches) s.query],
      snapshots: Float64List.fromList([
        _ms(loaded.history.watchesSnapshot),
        _ms(loaded.history.searchesSnapshot),
      ]),
      watchDayKeys: Int32List.fromList(loaded.watchDayKeys),
      searchDayKeys: Int32List.fromList(loaded.searchDayKeys),
      watchChannelIndex: loaded.watchChannelIndex,
      channelIds: [for (final c in channels) c.channel.channelId],
      channelTitles: [for (final c in channels) c.channel.title],
      channelUrls: [for (final c in channels) c.channel.channelUrl],
      channelCounts: Int32List.fromList([for (final c in channels) c.count]),
      channelLastWatched: Float64List.fromList([
        for (final c in channels) _ms(c.lastWatched),
      ]),
      recentChannelIds: loaded.recentChannelIds,
      counts: Int32List.fromList([
        loaded.removedWatchCount,
        loaded.removedSearchCount,
        loaded.shortCount,
        loaded.musicCount,
      ]),
      all: HistoryMatches.of(defaultResults(loaded)),
    );
  }

  List<Object?> toWire() => [
    watchTimes,
    watchKinds,
    watchMusic,
    watchRemovedAt,
    watchTitles,
    watchUrls,
    watchChannelTitles,
    watchChannelUrls,
    searchTimes,
    searchMusic,
    searchRemovedAt,
    searchQueries,
    snapshots,
    watchDayKeys,
    searchDayKeys,
    watchChannelIndex,
    channelIds,
    channelTitles,
    channelUrls,
    channelCounts,
    channelLastWatched,
    recentChannelIds,
    counts,
    all.toWire(),
  ];

  factory HistoryRows.fromWire(List<Object?> wire) => HistoryRows._(
    watchTimes: _doubles(wire[0]),
    watchKinds: _bytes(wire[1]),
    watchMusic: _bytes(wire[2]),
    watchRemovedAt: _doubles(wire[3]),
    watchTitles: _maybeStrings(wire[4]),
    watchUrls: _strings(wire[5]),
    watchChannelTitles: _maybeStrings(wire[6]),
    watchChannelUrls: _maybeStrings(wire[7]),
    searchTimes: _doubles(wire[8]),
    searchMusic: _bytes(wire[9]),
    searchRemovedAt: _doubles(wire[10]),
    searchQueries: _strings(wire[11]),
    snapshots: _doubles(wire[12]),
    watchDayKeys: _ints(wire[13]),
    searchDayKeys: _ints(wire[14]),
    watchChannelIndex: _ints(wire[15]),
    channelIds: _maybeStrings(wire[16]),
    channelTitles: _strings(wire[17]),
    channelUrls: _maybeStrings(wire[18]),
    channelCounts: _ints(wire[19]),
    channelLastWatched: _doubles(wire[20]),
    recentChannelIds: _strings(wire[21]),
    counts: _ints(wire[22]),
    all: HistoryMatches.fromWire(wire[23]! as List<Object?>),
  );

  int get removedWatchCount => counts[0];
  int get removedSearchCount => counts[1];
  int get shortCount => counts[2];
  int get musicCount => counts[3];

  /// The history these rows hold; each entry is made when first read.
  TakeoutHistory toHistory() => TakeoutHistory(
    watches: _Lazy(
      watchTimes.length,
      (i) => WatchEntry(
        time: _time(watchTimes[i])!,
        kind: WatchKind.values[watchKinds[i]],
        music: watchMusic[i] == 1,
        title: watchTitles[i],
        url: watchUrls[i],
        channelTitle: watchChannelTitles[i],
        channelUrl: watchChannelUrls[i],
        removedAt: _time(watchRemovedAt[i]),
      ),
    ),
    searches: _Lazy(
      searchTimes.length,
      (i) => SearchEntry(
        time: _time(searchTimes[i])!,
        music: searchMusic[i] == 1,
        query: searchQueries[i],
        removedAt: _time(searchRemovedAt[i]),
      ),
    ),
    watchesSnapshot: _time(snapshots[0]),
    searchesSnapshot: _time(snapshots[1]),
  );

  /// The watched channels, the most watched first.
  List<WatchedChannel> watchedChannels() => [
    for (var c = 0; c < channelTitles.length; c++)
      WatchedChannel(
        channel: HistoryChannel(
          channelId: channelIds[c],
          title: channelTitles[c],
          channelUrl: channelUrls[c],
        ),
        count: channelCounts[c],
        lastWatched: _time(channelLastWatched[c])!,
      ),
  ];
}

/// What the history is searched for: text, only what was removed, whether
/// Shorts and YouTube Music show, and which watched channels show (one flag
/// each, in the loaded history's order; null for every channel and the
/// videos without one). Which videos are Shorts the History worker knows.
class HistoryQuery {
  final String query;
  final bool removedOnly;
  final ShowFilter shorts;
  final ShowFilter music;
  final Uint8List? channelMask;

  const HistoryQuery({
    this.query = '',
    this.removedOnly = false,
    this.shorts = ShowFilter.all,
    this.music = ShowFilter.all,
    this.channelMask,
  });

  List<Object?> toWire() => [
    query,
    removedOnly,
    shorts.index,
    music.index,
    channelMask,
  ];

  factory HistoryQuery.fromWire(List<Object?> wire) => HistoryQuery(
    query: wire[0]! as String,
    removedOnly: wire[1]! as bool,
    shorts: ShowFilter.values[(wire[2]! as num).toInt()],
    music: ShowFilter.values[(wire[3]! as num).toInt()],
    channelMask: wire[4] == null ? null : _bytes(wire[4]),
  );
}

/// What a search shows, as lists of indices with where each group starts,
/// so the screen takes each group as a view, never a copy: the watched
/// videos by day and by month, the searches by day, and the watched videos
/// by channel. [generation] is the search's, so an older answer can be
/// told from a newer one.
class HistoryMatches {
  final int generation;
  final Int32List watchIndices;
  final Int32List dayKeys;
  final Int32List dayStarts;
  final Int32List monthKeys;
  final Int32List monthStarts;
  final Int32List searchIndices;
  final Int32List searchDayKeys;
  final Int32List searchDayStarts;

  /// Each group's channel, as its place in the watched channels; -1 for the
  /// videos without one.
  final Int32List channelOrder;
  final Int32List channelStarts;
  final Int32List channelMembers;

  HistoryMatches._({
    required this.generation,
    required this.watchIndices,
    required this.dayKeys,
    required this.dayStarts,
    required this.monthKeys,
    required this.monthStarts,
    required this.searchIndices,
    required this.searchDayKeys,
    required this.searchDayStarts,
    required this.channelOrder,
    required this.channelStarts,
    required this.channelMembers,
  });

  factory HistoryMatches.of(HistoryResults results, {int generation = 0}) {
    ({Int32List indices, Int32List keys, Int32List starts}) runs(
      List<HistoryDay> days,
    ) {
      final indices = <int>[];
      final keys = <int>[];
      final starts = <int>[];
      for (final day in days) {
        keys.add(day.dayKey);
        starts.add(indices.length);
        indices.addAll(day.indices);
      }
      starts.add(indices.length);
      return (
        indices: Int32List.fromList(indices),
        keys: Int32List.fromList(keys),
        starts: Int32List.fromList(starts),
      );
    }

    final watched = runs(results.watchDays);
    final months = runs(monthsOf(results.watchDays));
    final searched = runs(results.searchDays);
    final byKey = results.loaded.channelIndexByKey;
    final groups = results.channelGroups.groups;
    final members = <int>[];
    final starts = <int>[];
    for (final group in groups) {
      starts.add(members.length);
      members.addAll(group.indices);
    }
    starts.add(members.length);
    return HistoryMatches._(
      generation: generation,
      watchIndices: watched.indices,
      dayKeys: watched.keys,
      dayStarts: watched.starts,
      monthKeys: months.keys,
      monthStarts: months.starts,
      searchIndices: searched.indices,
      searchDayKeys: searched.keys,
      searchDayStarts: searched.starts,
      channelOrder: Int32List.fromList([
        for (final group in groups)
          group.channel == null ? -1 : byKey[group.key] ?? -1,
      ]),
      channelStarts: Int32List.fromList(starts),
      channelMembers: Int32List.fromList(members),
    );
  }

  List<Object?> toWire() => [
    generation,
    watchIndices,
    dayKeys,
    dayStarts,
    monthKeys,
    monthStarts,
    searchIndices,
    searchDayKeys,
    searchDayStarts,
    channelOrder,
    channelStarts,
    channelMembers,
  ];

  factory HistoryMatches.fromWire(List<Object?> wire) => HistoryMatches._(
    generation: (wire[0]! as num).toInt(),
    watchIndices: _ints(wire[1]),
    dayKeys: _ints(wire[2]),
    dayStarts: _ints(wire[3]),
    monthKeys: _ints(wire[4]),
    monthStarts: _ints(wire[5]),
    searchIndices: _ints(wire[6]),
    searchDayKeys: _ints(wire[7]),
    searchDayStarts: _ints(wire[8]),
    channelOrder: _ints(wire[9]),
    channelStarts: _ints(wire[10]),
    channelMembers: _ints(wire[11]),
  );

  List<HistoryDay> watchDays() => _days(dayKeys, dayStarts, watchIndices);

  /// By month: each key is `yyyymm00`, each day the month's first.
  List<HistoryDay> watchMonths() => _days(monthKeys, monthStarts, watchIndices);

  List<HistoryDay> searchDays() =>
      _days(searchDayKeys, searchDayStarts, searchIndices);

  /// The watched videos by channel, [channels] being the loaded history's.
  ChannelGroups channelGroups(List<WatchedChannel> channels) =>
      ChannelGroups.ofRuns(
        channels: channels,
        order: channelOrder,
        starts: channelStarts,
        members: channelMembers,
      );

  static List<HistoryDay> _days(
    Int32List keys,
    Int32List starts,
    Int32List indices,
  ) => [
    for (var d = 0; d < keys.length; d++)
      (
        dayKey: keys[d],
        day: keys[d] % 100 == 0
            ? DateTime(keys[d] ~/ 10000, keys[d] ~/ 100 % 100)
            : DateTime(keys[d] ~/ 10000, keys[d] ~/ 100 % 100, keys[d] % 100),
        indices: Int32List.sublistView(indices, starts[d], starts[d + 1]),
      ),
  ];
}

/// The videos picked for AI, per watched channel, for the wire.
List<Object?> promptPicksToWire(List<PromptPicks> picks) {
  final titleStarts = <int>[];
  final titles = <int>[];
  final describedStarts = <int>[];
  final described = <int>[];
  for (final pick in picks) {
    titleStarts.add(titles.length);
    titles.addAll(pick.titles);
    describedStarts.add(described.length);
    described.addAll(pick.described);
  }
  titleStarts.add(titles.length);
  describedStarts.add(described.length);
  return [
    Int32List.fromList(titleStarts),
    Int32List.fromList(titles),
    Int32List.fromList(describedStarts),
    Int32List.fromList(described),
  ];
}

List<PromptPicks> promptPicksFromWire(List<Object?> wire) {
  final titleStarts = _ints(wire[0]);
  final titles = _ints(wire[1]);
  final describedStarts = _ints(wire[2]);
  final described = _ints(wire[3]);
  return [
    for (var c = 0; c < titleStarts.length - 1; c++)
      (
        titles: Int32List.sublistView(
          titles,
          titleStarts[c],
          titleStarts[c + 1],
        ),
        described: Int32List.sublistView(
          described,
          describedStarts[c],
          describedStarts[c + 1],
        ),
      ),
  ];
}
