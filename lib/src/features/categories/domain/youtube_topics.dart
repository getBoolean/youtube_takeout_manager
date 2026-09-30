import 'category_path.dart';

/// YouTube's channel topics, by the Wikipedia page naming each, as the
/// categories and sub-categories they are.
const youtubeTopicCategories = <String, CategoryPath>{
  'Video_game_culture': CategoryPath('Gaming'),
  'Action_game': CategoryPath('Gaming', 'Action'),
  'Action-adventure_game': CategoryPath('Gaming', 'Action-adventure'),
  'Casual_game': CategoryPath('Gaming', 'Casual'),
  'Music_video_game': CategoryPath('Gaming', 'Music games'),
  'Puzzle_video_game': CategoryPath('Gaming', 'Puzzle'),
  'Racing_video_game': CategoryPath('Gaming', 'Racing'),
  'Role-playing_video_game': CategoryPath('Gaming', 'Role-playing'),
  'Simulation_video_game': CategoryPath('Gaming', 'Simulation'),
  'Sports_game': CategoryPath('Gaming', 'Sports games'),
  'Strategy_video_game': CategoryPath('Gaming', 'Strategy'),
  'Music': CategoryPath('Music'),
  'Christian_music': CategoryPath('Music', 'Christian'),
  'Classical_music': CategoryPath('Music', 'Classical'),
  'Country_music': CategoryPath('Music', 'Country'),
  'Electronic_music': CategoryPath('Music', 'Electronic'),
  'Hip_hop_music': CategoryPath('Music', 'Hip hop'),
  'Independent_music': CategoryPath('Music', 'Independent'),
  'Jazz': CategoryPath('Music', 'Jazz'),
  'Music_of_Asia': CategoryPath('Music', 'Asian music'),
  'Music_of_Latin_America': CategoryPath('Music', 'Latin music'),
  'Pop_music': CategoryPath('Music', 'Pop'),
  'Reggae': CategoryPath('Music', 'Reggae'),
  'Rhythm_and_blues': CategoryPath('Music', 'R&B'),
  'Rock_music': CategoryPath('Music', 'Rock'),
  'Soul_music': CategoryPath('Music', 'Soul'),
  'Sport': CategoryPath('Sports'),
  'American_football': CategoryPath('Sports', 'American football'),
  'Baseball': CategoryPath('Sports', 'Baseball'),
  'Basketball': CategoryPath('Sports', 'Basketball'),
  'Boxing': CategoryPath('Sports', 'Boxing'),
  'Cricket': CategoryPath('Sports', 'Cricket'),
  'Association_football': CategoryPath('Sports', 'Football'),
  'Golf': CategoryPath('Sports', 'Golf'),
  'Ice_hockey': CategoryPath('Sports', 'Ice hockey'),
  'Mixed_martial_arts': CategoryPath('Sports', 'Mixed martial arts'),
  'Motorsport': CategoryPath('Sports', 'Motorsport'),
  'Professional_wrestling': CategoryPath('Sports', 'Wrestling'),
  'Tennis': CategoryPath('Sports', 'Tennis'),
  'Volleyball': CategoryPath('Sports', 'Volleyball'),
  'Entertainment': CategoryPath('Entertainment'),
  'Humour': CategoryPath('Entertainment', 'Humor'),
  'Film': CategoryPath('Entertainment', 'Movies'),
  'Performing_arts': CategoryPath('Entertainment', 'Performing arts'),
  'Television_program': CategoryPath('Entertainment', 'TV shows'),
  'Lifestyle_(sociology)': CategoryPath('Lifestyle'),
  'Physical_attractiveness': CategoryPath('Lifestyle', 'Beauty'),
  'Fashion': CategoryPath('Lifestyle', 'Fashion'),
  'Physical_fitness': CategoryPath('Lifestyle', 'Fitness'),
  'Food': CategoryPath('Lifestyle', 'Food'),
  'Hobby': CategoryPath('Lifestyle', 'Hobbies'),
  'Pet': CategoryPath('Lifestyle', 'Pets'),
  'Technology': CategoryPath('Lifestyle', 'Technology'),
  'Tourism': CategoryPath('Lifestyle', 'Travel'),
  'Vehicle': CategoryPath('Lifestyle', 'Vehicles'),
  'Society': CategoryPath('Society'),
  'Business': CategoryPath('Society', 'Business'),
  'Health': CategoryPath('Society', 'Health'),
  'Military': CategoryPath('Society', 'Military'),
  'Politics': CategoryPath('Society', 'Politics'),
  'Religion': CategoryPath('Society', 'Religion'),
  'Knowledge': CategoryPath('Knowledge'),
};

/// The Wikipedia page a topic link names, decoded, or null.
String? _slugOf(String url) {
  final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
  if (segments.length < 2 || segments[segments.length - 2] != 'wiki') {
    return null;
  }
  return segments.last;
}

/// The category a YouTube topic link is, or null for a topic it has none
/// for.
CategoryPath? categoryOfTopic(String url) =>
    youtubeTopicCategories[_slugOf(url) ?? ''];

/// A topic link as the topic's name, e.g. "Role-playing video game".
String topicLabel(String url) => (_slugOf(url) ?? url).replaceAll('_', ' ');

/// The categories a channel's topics suggest: its sub-categories when it
/// has any, else its categories, each once, in order.
List<CategoryPath> youtubeCandidates(Iterable<String> topicUrls) {
  final paths = <CategoryPath>{
    for (final url in topicUrls) ?categoryOfTopic(url),
  };
  final children = [
    for (final p in paths)
      if (p.child != null) p,
  ];
  return children.isNotEmpty ? children : paths.toList();
}
