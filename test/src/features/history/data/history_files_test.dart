import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/data/history_files.dart';

void main() {
  const dir = 'Takeout/YouTube and YouTube Music/history';

  test("finds Google's history files in either format, whatever the case", () {
    expect(
      HistoryFile.classify('0/$dir/watch-history.html'),
      HistoryFile.watches,
    );
    expect(
      HistoryFile.classify('0/$dir/watch-history.json'),
      HistoryFile.watches,
    );
    expect(
      HistoryFile.classify('1/${dir.toUpperCase()}/SEARCH-HISTORY.HTML'),
      HistoryFile.searches,
    );
    expect(HistoryFile.watches.fromGoogle, isTrue);
  });

  test('ignores files that only look like history', () {
    expect(HistoryFile.classify('$dir/watch-history.csv'), isNull);
    expect(HistoryFile.classify('$dir/archive_browser.html'), isNull);
    expect(HistoryFile.classify('watch-history.html.bak'), isNull);
  });

  test("tells the app's saved history files from Google's", () {
    for (final path in [
      '_history/watches.csv',
      '_history/searches.csv',
      '_history/meta.csv',
    ]) {
      expect(isHistoryPath(path), isTrue, reason: path);
      expect(HistoryFile.classify(path)?.fromGoogle, isFalse, reason: path);
    }
    expect(isHistoryPath('comments/comments.csv'), isFalse);
    expect(isHistoryPath('_meta/takeout_meta.csv'), isFalse);
    expect(isHistoryPath('$dir/watch-history.html'), isFalse);
  });
}
