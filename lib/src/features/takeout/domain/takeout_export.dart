import 'takeout_data.dart';

/// Row counts of one kind's numbered CSV files, e.g. `comments(3).csv` is
/// page 3 and `comments.csv` is page 0. A set, so the same file picked twice
/// counts once.
typedef CsvPages = Set<({int page, int rows})>;

/// One takeout export read from the zips picked for it.
class TakeoutExport {
  /// When Google exported it, from its zips' names, or null when they were
  /// renamed.
  final DateTime? exportedAt;

  final TakeoutData data;

  /// How its comments and live chats were split across numbered files.
  final CsvPages commentPages;
  final CsvPages liveChatPages;

  const TakeoutExport({
    this.exportedAt,
    required this.data,
    this.commentPages = const {},
    this.liveChatPages = const {},
  });
}
