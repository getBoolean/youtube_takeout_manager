import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

part 'watch_entry.mapper.dart';

/// What a watch history entry was of, told apart by its link.
@MappableEnum()
enum WatchKind { video, post, playable }

/// One entry of YouTube's watch history.
@MappableClass()
class WatchEntry with WatchEntryMappable {
  /// When it was watched, in UTC.
  final DateTime time;

  final WatchKind kind;

  /// Watched on YouTube Music.
  final bool music;

  /// Null when the video was removed or made private before the export.
  final String? title;

  /// Its link on YouTube (or YouTube Music).
  final String url;

  /// The uploader, unknown when [title] is.
  final String? channelTitle;
  final String? channelUrl;

  /// When a newer takeout's history first lacked it, meaning it was since
  /// removed from YouTube's history; null while it's still there.
  final DateTime? removedAt;

  WatchEntry({
    required this.time,
    required this.kind,
    this.music = false,
    this.title,
    required this.url,
    this.channelTitle,
    this.channelUrl,
    this.removedAt,
  }) : searchText = foldForSearch('${title ?? url}\n${channelTitle ?? ''}');

  /// The video's ID, when it's a video.
  String? get videoId => kind == WatchKind.video
      ? _videoIdPattern.firstMatch(url)?.group(1)
      : null;

  /// The uploader's channel ID, when its link has one.
  String? get channelId => switch (channelUrl) {
    final url? => _channelIdPattern.firstMatch(url)?.group(1),
    null => null,
  };

  /// Title and channel folded for search, worked out once.
  final String searchText;

  static final _videoIdPattern = RegExp(r'(?:[?&]v=|/shorts/)([\w-]+)');
  static final _channelIdPattern = RegExp(r'/channel/([\w-]+)');
}
