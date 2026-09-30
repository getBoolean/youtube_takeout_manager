import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';

/// What an AI is told about a channel to pick its category: its name and
/// description, YouTube's topics for it, and the titles of videos watched
/// from it.
class ChannelEvidence {
  final String title;
  final String? description;
  final List<String> topicLabels;
  final List<String> recentTitles;

  const ChannelEvidence({
    required this.title,
    this.description,
    this.topicLabels = const [],
    this.recentTitles = const [],
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
    if (recentTitles.isNotEmpty) 'watched_video_titles': recentTitles,
  };
}

/// The titles of each watched channel's most recently watched videos,
/// newest first, up to [max] each, by the channel's place in [loaded]'s
/// watched channels. One pass over the history.
List<List<String>> recentTitlesByChannel(LoadedHistory loaded, {int max = 30}) {
  final titles = [
    for (var c = 0; c < loaded.watchedChannels.length; c++) <String>[],
  ];
  final watches = loaded.history.watches;
  for (var i = 0; i < watches.length; i++) {
    final c = loaded.watchChannelIndex[i];
    if (c < 0 || titles[c].length >= max) continue;
    if (watches[i].title case final title?) titles[c].add(title);
  }
  return titles;
}
