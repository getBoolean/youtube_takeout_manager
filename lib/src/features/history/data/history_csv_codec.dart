import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/csv_header.dart';
import '../domain/loaded_history.dart';
import '../domain/search_entry.dart';
import '../domain/takeout_history.dart';
import '../domain/watch_entry.dart';
import 'history_files.dart';

// The app wrote these files itself, so the delimiter needn't be guessed.
final _csv = Csv(autoDetect: false);

/// Encodes [history] as the CSV files a takeout's folder saves it in, which
/// [parseSavedHistory] reads back into the same history.
Map<String, Uint8List> encodeHistoryCsvs(TakeoutHistory history) => {
  HistoryFile.savedWatches.savedPath!: _encode([
    [
      'Time',
      'Kind',
      'Music',
      'Title',
      'URL',
      'Channel Title',
      'Channel URL',
      'Removed At',
    ],
    for (final w in history.watches)
      [
        _timestamp(w.time),
        w.kind.name,
        w.music,
        w.title ?? '',
        w.url,
        w.channelTitle ?? '',
        w.channelUrl ?? '',
        _optionalTimestamp(w.removedAt),
      ],
  ]),
  HistoryFile.savedSearches.savedPath!: _encode([
    ['Time', 'Music', 'Query', 'Removed At'],
    for (final s in history.searches)
      [_timestamp(s.time), s.music, s.query, _optionalTimestamp(s.removedAt)],
  ]),
  HistoryFile.savedMeta.savedPath!: _encode([
    ['Watches Exported At', 'Searches Exported At'],
    [
      _optionalTimestamp(history.watchesSnapshot),
      _optionalTimestamp(history.searchesSnapshot),
    ],
  ]),
};

/// Reads the history saved in a takeout's folder from its saved history
/// [files], keyed by path. Top-level so it can run in an isolate.
TakeoutHistory parseSavedHistory(Map<String, Uint8List> files) {
  final watches = <WatchEntry>[];
  final searches = <SearchEntry>[];
  DateTime? watchesSnapshot, searchesSnapshot;
  for (final MapEntry(key: path, value: bytes) in files.entries) {
    switch (HistoryFile.classify(path)) {
      case HistoryFile.savedWatches:
        watches.addAll(_readWatches(bytes));
      case HistoryFile.savedSearches:
        searches.addAll(_readSearches(bytes));
      case HistoryFile.savedMeta:
        final rows = _rows(bytes, 'saved history times');
        if (rows == null || rows.rows.isEmpty) continue;
        final row = rows.rows.first;
        watchesSnapshot = _time(
          row,
          rows.header.optional('watches exported at'),
        );
        searchesSnapshot = _time(
          row,
          rows.header.optional('searches exported at'),
        );
      case HistoryFile.watches || HistoryFile.searches || null:
        continue;
    }
  }
  return TakeoutHistory(
    watches: watches,
    searches: searches,
    watchesSnapshot: watchesSnapshot,
    searchesSnapshot: searchesSnapshot,
  );
}

Iterable<WatchEntry> _readWatches(Uint8List bytes) sync* {
  final rows = _rows(bytes, 'saved watch history');
  if (rows == null) return;
  final h = rows.header;
  final (iTime, iUrl) = (h.required('Time'), h.required('URL'));
  final (iKind, iMusic, iTitle) = (
    h.optional('kind'),
    h.optional('music'),
    h.optional('title'),
  );
  final (iChannel, iChannelUrl, iRemoved) = (
    h.optional('channel title'),
    h.optional('channel url'),
    h.optional('removed at'),
  );
  for (final row in rows.rows) {
    final time = _time(row, iTime);
    final url = _field(row, iUrl);
    if (time == null || url == null) continue;
    yield WatchEntry(
      time: time,
      kind: WatchKind.values.asNameMap()[_field(row, iKind)] ?? WatchKind.video,
      music: _field(row, iMusic) == 'true',
      title: _field(row, iTitle),
      url: url,
      channelTitle: _field(row, iChannel),
      channelUrl: _field(row, iChannelUrl),
      removedAt: _time(row, iRemoved),
    );
  }
}

Iterable<SearchEntry> _readSearches(Uint8List bytes) sync* {
  final rows = _rows(bytes, 'saved search history');
  if (rows == null) return;
  final h = rows.header;
  final (iTime, iQuery) = (h.required('Time'), h.required('Query'));
  final (iMusic, iRemoved) = (h.optional('music'), h.optional('removed at'));
  for (final row in rows.rows) {
    final time = _time(row, iTime);
    final query = _field(row, iQuery);
    if (time == null || query == null) continue;
    yield SearchEntry(
      time: time,
      music: _field(row, iMusic) == 'true',
      query: query,
      removedAt: _time(row, iRemoved),
    );
  }
}

/// [bytes]'s header and data rows, or null when it has no header.
({CsvHeader header, Iterable<List<dynamic>> rows})? _rows(
  Uint8List bytes,
  String file,
) {
  final rows = _csv.decode(utf8.decode(bytes));
  if (rows.isEmpty) return null;
  return (header: CsvHeader(rows.first, file), rows: rows.skip(1));
}

/// The value at [index] in [row], or null when it's empty or missing.
String? _field(List<dynamic> row, int? index) {
  if (index == null || index >= row.length) return null;
  final value = row[index]?.toString() ?? '';
  return value.isEmpty ? null : value;
}

DateTime? _time(List<dynamic> row, int? index) => switch (_field(row, index)) {
  final text? => DateTime.tryParse(text)?.toUtc(),
  null => null,
};

String _timestamp(DateTime t) => t.toUtc().toIso8601String();

String _optionalTimestamp(DateTime? t) => t == null ? '' : _timestamp(t);

Uint8List _encode(List<List<Object>> rows) =>
    Uint8List.fromList(utf8.encode(_csv.encode(rows)));

/// Reads saved history [files] as [parseSavedHistory] does, and works out
/// what showing it needs. Top-level so it can run in an isolate.
LoadedHistory loadSavedHistory(Map<String, Uint8List> files) =>
    LoadedHistory.of(parseSavedHistory(files));
