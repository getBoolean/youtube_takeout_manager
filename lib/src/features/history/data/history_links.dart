import '../domain/watch_entry.dart';

/// What a watch history entry linking to [url] was of, or null for links
/// that aren't something watched. Told by the link because the words around
/// it are in the export's language.
WatchKind? watchKindOf(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final path = uri.path;
  if ((path == '/watch' && uri.queryParameters['v'] != null) ||
      path.startsWith('/shorts/')) {
    return WatchKind.video;
  }
  if (path.startsWith('/post/')) return WatchKind.post;
  if (path.startsWith('/playables/')) return WatchKind.playable;
  return null;
}

/// The query of a search history entry linking to [url], or null when it
/// isn't a search.
String? searchQueryOf(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  return uri.queryParameters['search_query'] ?? uri.queryParameters['q'];
}

/// Whether [url] is on YouTube Music.
bool isMusicUrl(String url) => Uri.tryParse(url)?.host == 'music.youtube.com';

/// Whether [url] is a channel's page.
bool isChannelUrl(String url) =>
    Uri.tryParse(url)?.path.startsWith('/channel/') ?? false;
