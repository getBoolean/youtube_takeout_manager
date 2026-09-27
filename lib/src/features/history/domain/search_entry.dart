import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

part 'search_entry.mapper.dart';

/// One entry of YouTube's search history.
@MappableClass()
class SearchEntry with SearchEntryMappable {
  /// When it was searched for, in UTC.
  final DateTime time;

  /// Searched for on YouTube Music.
  final bool music;

  final String query;

  /// When a newer takeout's history first lacked it, meaning it was since
  /// removed from YouTube's history; null while it's still there.
  final DateTime? removedAt;

  SearchEntry({
    required this.time,
    this.music = false,
    required this.query,
    this.removedAt,
  }) : searchText = foldForSearch(query);

  /// The search on YouTube (or YouTube Music).
  Uri get url => Uri.https(
    music ? 'music.youtube.com' : 'www.youtube.com',
    music ? '/search' : '/results',
    {music ? 'q' : 'search_query': query},
  );

  /// The query folded for search, worked out once.
  final String searchText;
}
