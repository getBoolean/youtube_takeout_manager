import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

import 'prompt_videos.dart';

/// What an AI is told about a channel to pick its category: its name and
/// description, YouTube's topics for it, and the titles of videos watched
/// from it, some with their descriptions.
class ChannelEvidence {
  final String title;
  final String? description;
  final List<String> topicLabels;
  final List<String> titles;
  final List<({String title, String description})> videoDescriptions;

  const ChannelEvidence({
    required this.title,
    this.description,
    this.topicLabels = const [],
    this.titles = const [],
    this.videoDescriptions = const [],
  });

  /// Descriptions are cut to this many characters.
  static const maxDescription = 500;

  /// As JSON for the AI, leaving out what's missing.
  Map<String, Object> toState() => {
    'channel': title,
    if (description case final d? when d.trim().isNotEmpty)
      'description': d.length <= maxDescription
          ? d
          : d.substring(0, maxDescription),
    if (topicLabels.isNotEmpty) 'youtube_topics': topicLabels,
    if (titles.isNotEmpty) 'watched_video_titles': titles,
    if (videoDescriptions.isNotEmpty)
      'watched_video_descriptions': [
        for (final (:title, :description) in videoDescriptions)
          {'title': title, 'description': description},
      ],
  };
}

/// The evidence for the channel [title]: the titles of its [picks] among
/// [watches], and the descriptions of the ones picked for that, from
/// [descriptions] by video ID, cleaned; ones not known are left out.
ChannelEvidence buildEvidence({
  required String title,
  String? description,
  List<String> topicLabels = const [],
  required PromptPicks picks,
  required List<WatchEntry> watches,
  required Map<String, String?> descriptions,
}) => ChannelEvidence(
  title: title,
  description: description,
  topicLabels: topicLabels,
  titles: [for (final i in picks.titles) ?watches[i].title],
  videoDescriptions: [
    for (final i in picks.described)
      if ((watches[i].title, cleanDescription(descriptions[watches[i].videoId]))
          case (final title?, final description?))
        (title: title, description: description),
  ],
);
