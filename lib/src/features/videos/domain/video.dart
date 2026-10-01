import 'package:dart_mappable/dart_mappable.dart';

part 'video.mapper.dart';

@MappableClass()
class Video with VideoMappable {
  final String videoId;
  final String channelId;
  final String? channelTitle;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final DateTime? publishedAt;

  /// Descriptions are kept cut to this many characters: nothing shows
  /// them, and AI is told far less.
  static const maxDescription = 1000;

  const Video({
    required this.videoId,
    required this.channelId,
    this.channelTitle,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.publishedAt,
  });
}
