import 'package:flutter/foundation.dart';

/// What a channel says about itself, from the YouTube API: the topics
/// YouTube gives it and its description, for telling what it posts.
@immutable
class ChannelDetails {
  /// Wikipedia links naming its topics, e.g.
  /// `https://en.wikipedia.org/wiki/Video_game_culture`.
  final List<String> topicUrls;
  final String? description;

  const ChannelDetails({this.topicUrls = const [], this.description});

  /// Descriptions are cut to this many characters: enough to tell what a
  /// channel posts, little to keep for thousands of channels.
  static const maxDescription = 400;

  factory ChannelDetails.fromApi({
    List<String>? topicCategories,
    String? description,
  }) {
    final text = description?.trim() ?? '';
    return ChannelDetails(
      topicUrls: List.unmodifiable(topicCategories ?? const <String>[]),
      description: text.isEmpty
          ? null
          : text.length <= maxDescription
          ? text
          : text.substring(0, maxDescription),
    );
  }

  Map<String, Object?> toJson() => {
    if (topicUrls.isNotEmpty) 't': topicUrls,
    'd': ?description,
  };

  factory ChannelDetails.fromJson(Map<String, dynamic> json) => ChannelDetails(
    topicUrls: List.unmodifiable(
      (json['t'] as List<dynamic>? ?? const []).cast<String>(),
    ),
    description: json['d'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is ChannelDetails &&
      listEquals(other.topicUrls, topicUrls) &&
      other.description == description;

  @override
  int get hashCode => Object.hash(Object.hashAll(topicUrls), description);
}
