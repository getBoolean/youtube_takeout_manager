import 'search_entry.dart';
import 'watch_entry.dart';

/// A takeout account's watch and search history, merged from every takeout
/// imported for it.
///
/// Compared by identity: comparing tens of thousands of entries on every
/// provider update would be slow, and a new history is a new instance.
class TakeoutHistory {
  /// Newest first.
  final List<WatchEntry> watches;

  /// Newest first.
  final List<SearchEntry> searches;

  /// When the newest export with each kind of history was made, or null
  /// when none had it.
  final DateTime? watchesSnapshot;
  final DateTime? searchesSnapshot;

  const TakeoutHistory({
    this.watches = const [],
    this.searches = const [],
    this.watchesSnapshot,
    this.searchesSnapshot,
  });

  static const empty = TakeoutHistory();

  bool get isEmpty => watches.isEmpty && searches.isEmpty;
}

/// What one of a takeout export's history files held.
class HistoryFileRead<T> {
  final List<T> entries;

  /// Entries that couldn't be read, e.g. for an unreadable date.
  final int skippedRows;

  /// It had entries but none could be read, e.g. HTML in another language.
  final bool unreadable;

  const HistoryFileRead({
    required this.entries,
    this.skippedRows = 0,
    this.unreadable = false,
  });

  /// Whether it can be trusted to list everything still in the history.
  bool get complete => skippedRows == 0 && !unreadable;
}

/// The history one takeout export held. A kind is null when the export had
/// no file for it.
class ExportHistory {
  /// When Google exported it, or null when its zips were renamed.
  final DateTime? exportedAt;

  final HistoryFileRead<WatchEntry>? watches;
  final HistoryFileRead<SearchEntry>? searches;

  const ExportHistory({this.exportedAt, this.watches, this.searches});

  bool get isEmpty => watches == null && searches == null;

  /// When it was exported; for renamed zips, when its newest entry was
  /// made, which is as late as it can be known to be from.
  DateTime get snapshot =>
      exportedAt ??
      [
        ...?watches?.entries.map((w) => w.time),
        ...?searches?.entries.map((s) => s.time),
      ].fold<DateTime?>(
        null,
        (newest, t) => newest == null || t.isAfter(newest) ? t : newest,
      ) ??
      DateTime.utc(1970);
}
