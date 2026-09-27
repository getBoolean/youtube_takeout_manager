/// The history files of a takeout: Google's, in HTML or JSON, and the
/// app's saved copies.
enum HistoryFile {
  /// `history/watch-history.html` or `.json` in Google's takeouts.
  watches,

  /// `history/search-history.html` or `.json` in Google's takeouts.
  searches,

  /// The app's own: the merged watch history.
  savedWatches,

  /// The app's own: the merged search history.
  savedSearches,

  /// The app's own: when the newest history of each kind was exported.
  savedMeta;

  /// Whether Google's takeouts have it, so it's taken from picked zips.
  bool get fromGoogle => this == watches || this == searches;

  /// Where the app saves it in a takeout's folder; null for Google's.
  String? get savedPath => switch (this) {
    savedWatches => '$_savedDir/watches.csv',
    savedSearches => '$_savedDir/searches.csv',
    savedMeta => '$_savedDir/meta.csv',
    watches || searches => null,
  };

  /// Which file [path] is, in a zip or a saved takeout's folder, or null if
  /// it isn't one. Case doesn't matter.
  static HistoryFile? classify(String path) {
    final lower = path.toLowerCase();
    for (final (name, file) in [
      ('/history/watch-history', watches),
      ('/history/search-history', searches),
    ]) {
      if (lower.endsWith('$name.html') || lower.endsWith('$name.json')) {
        return file;
      }
    }
    for (final file in [savedWatches, savedSearches, savedMeta]) {
      if (lower == file.savedPath) return file;
    }
    return null;
  }
}

const _savedDir = '_history';

/// Whether [path], in a saved takeout's folder, is one of the app's saved
/// history files, which are loaded apart from the rest of the takeout.
bool isHistoryPath(String path) =>
    HistoryFile.classify(path)?.fromGoogle == false;
