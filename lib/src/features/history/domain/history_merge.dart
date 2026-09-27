import 'search_entry.dart';
import 'takeout_history.dart';
import 'watch_entry.dart';

/// What importing takeouts would do to an account's history.
class HistoryImport {
  /// The history to save, or null to keep the saved history as it is
  /// because no picked takeout had any.
  final TakeoutHistory? merged;

  /// Entries the saved history didn't have.
  final int newWatchCount;
  final int newSearchCount;

  /// Entries the newest history no longer has, marked removed by this
  /// import.
  final int newlyRemovedWatchCount;
  final int newlyRemovedSearchCount;

  /// The newest history of a kind had entries it couldn't read, so which
  /// entries were removed wasn't worked out for it.
  final bool removalCheckSkipped;

  /// Entries the picked history files had but couldn't be read.
  final int skippedRows;

  /// Picked history files that had entries but none could be read.
  final int unreadableFiles;

  const HistoryImport({
    this.merged,
    this.newWatchCount = 0,
    this.newSearchCount = 0,
    this.newlyRemovedWatchCount = 0,
    this.newlyRemovedSearchCount = 0,
    this.removalCheckSkipped = false,
    this.skippedRows = 0,
    this.unreadableFiles = 0,
  });

  static const none = HistoryImport();

  /// Whether something went wrong reading it that should be shown first.
  bool get needsReview =>
      skippedRows > 0 || unreadableFiles > 0 || removalCheckSkipped;
}

/// Merges the history of [picked] takeout exports into the [saved] history
/// (null when there's none, or it's being replaced).
///
/// Entries are kept from every source, once each. Those the newest source
/// of their kind doesn't have are marked removed from YouTube's history,
/// unless that source couldn't all be read; those it has are unmarked.
HistoryImport planHistoryImport({
  TakeoutHistory? saved,
  required List<ExportHistory> picked,
}) {
  if (picked.every((p) => p.isEmpty)) return const HistoryImport();

  final watches = _mergeKind<WatchEntry>(
    saved: saved?.watches ?? const [],
    savedSnapshot: saved?.watchesSnapshot,
    picked: [
      for (final p in picked)
        if (p.watches case final read?) (snapshot: p.snapshot, read: read),
    ],
    keyOf: (w) => (w.kind, w.url, _seconds(w.time)),
    timeOf: (w) => w.time,
    removedAtOf: (w) => w.removedAt,
    withRemovedAt: (w, removedAt) => w.copyWith(removedAt: removedAt),
  );
  final searches = _mergeKind<SearchEntry>(
    saved: saved?.searches ?? const [],
    savedSnapshot: saved?.searchesSnapshot,
    picked: [
      for (final p in picked)
        if (p.searches case final read?) (snapshot: p.snapshot, read: read),
    ],
    keyOf: (s) => (s.query, _seconds(s.time)),
    timeOf: (s) => s.time,
    removedAtOf: (s) => s.removedAt,
    withRemovedAt: (s, removedAt) => s.copyWith(removedAt: removedAt),
  );

  final files = [
    for (final p in picked) ...[?p.watches, ?p.searches],
  ];
  return HistoryImport(
    merged: TakeoutHistory(
      watches: watches.entries,
      searches: searches.entries,
      watchesSnapshot: watches.snapshot,
      searchesSnapshot: searches.snapshot,
    ),
    newWatchCount: watches.added,
    newSearchCount: searches.added,
    newlyRemovedWatchCount: watches.newlyRemoved,
    newlyRemovedSearchCount: searches.newlyRemoved,
    removalCheckSkipped: watches.checkSkipped || searches.checkSkipped,
    skippedRows: files.fold(0, (sum, f) => sum + f.skippedRows),
    unreadableFiles: files.where((f) => f.unreadable).length,
  );
}

/// Seconds since the epoch: HTML exports give times to the second, JSON
/// ones to the millisecond, so the same entry from each matches on this.
int _seconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

typedef _Source<T> = ({DateTime snapshot, HistoryFileRead<T> read});

typedef _MergedKind<T> = ({
  List<T> entries,
  DateTime? snapshot,
  int added,
  int newlyRemoved,
  bool checkSkipped,
});

_MergedKind<T> _mergeKind<T>({
  required List<T> saved,
  required DateTime? savedSnapshot,
  required List<_Source<T>> picked,
  required Object Function(T) keyOf,
  required DateTime Function(T) timeOf,
  required DateTime? Function(T) removedAtOf,
  required T Function(T, DateTime? removedAt) withRemovedAt,
}) {
  if (picked.isEmpty) {
    return (
      entries: saved,
      snapshot: savedSnapshot,
      added: 0,
      newlyRemoved: 0,
      checkSkipped: false,
    );
  }

  // Oldest first, the saved history before picked ones made at the same
  // time, so newer sources overwrite older ones' entries.
  final sources =
      [
        if (savedSnapshot != null)
          (snapshot: savedSnapshot, read: HistoryFileRead(entries: saved)),
        ...picked,
      ].indexed.toList()..sort((a, b) {
        final byTime = a.$2.snapshot.compareTo(b.$2.snapshot);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });

  final savedKeys = {for (final e in saved) keyOf(e)};
  final merged = <Object, T>{};
  for (final (_, source) in sources) {
    for (final entry in source.read.entries) {
      final key = keyOf(entry);
      // An entry keeps when it was first missed until a source has it again.
      merged[key] = withRemovedAt(
        entry,
        removedAtOf(entry) ??
            switch (merged[key]) {
              final older? => removedAtOf(older),
              null => null,
            },
      );
    }
  }

  // The newest source says what's still in YouTube's history. The saved
  // history's still has what it hasn't marked removed.
  final newest = sources.last.$2;
  final checkSkipped = !newest.read.complete;
  var newlyRemoved = 0;
  if (!checkSkipped) {
    final present = {
      for (final e in newest.read.entries)
        if (removedAtOf(e) == null) keyOf(e),
    };
    for (final MapEntry(:key, value: entry) in merged.entries.toList()) {
      final removedAt = removedAtOf(entry);
      if (present.contains(key)) {
        if (removedAt != null) merged[key] = withRemovedAt(entry, null);
      } else if (removedAt == null) {
        merged[key] = withRemovedAt(entry, newest.snapshot);
        newlyRemoved++;
      }
    }
  }

  final entries = merged.values.toList()
    ..sort((a, b) => timeOf(b).compareTo(timeOf(a)));
  return (
    entries: entries,
    snapshot: newest.snapshot,
    added: merged.keys.where((k) => !savedKeys.contains(k)).length,
    newlyRemoved: newlyRemoved,
    checkSkipped: checkSkipped,
  );
}
