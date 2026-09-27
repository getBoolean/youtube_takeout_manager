import 'interaction.dart';
import 'queue_item_kind.dart';

/// [videoId]'s watch page.
Uri youtubeVideoUrl(String videoId) =>
    Uri.https('www.youtube.com', '/watch', {'v': videoId});

/// [postId]'s community post page.
Uri youtubePostUrl(String postId) =>
    Uri.https('www.youtube.com', '/post/$postId');

/// Where [item] is on YouTube, or null when it's on neither a video nor a
/// post. Comments open scrolled to themselves; live chats can't be linked
/// to, so they open their video.
Uri? youtubeUrlOf(Interaction item) {
  final highlight = {if (item.kind == QueueItemKind.comment) 'lc': item.id};
  return switch (item) {
    Interaction(:final videoId?) => Uri.https('www.youtube.com', '/watch', {
      'v': videoId,
      ...highlight,
    }),
    Interaction(:final postId?) => Uri.https(
      'www.youtube.com',
      '/post/$postId',
      highlight.isEmpty ? null : highlight,
    ),
    _ => null,
  };
}
