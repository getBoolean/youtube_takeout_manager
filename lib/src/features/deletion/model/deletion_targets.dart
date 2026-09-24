import 'deletion_queue_item.dart';
import 'queue_item_kind.dart';

/// Comments and live chats to delete from YouTube, keyed by ID with the text
/// snippet shown in the deletion queue.
class DeletionTargets {
  final Map<String, String?> commentSnippets;
  final Map<String, String?> liveChatSnippets;

  const DeletionTargets({
    this.commentSnippets = const {},
    this.liveChatSnippets = const {},
  });

  factory DeletionTargets.fromQueueItems(Iterable<DeletionQueueItem> items) {
    return DeletionTargets(
      commentSnippets: {
        for (final i in items)
          if (i.itemType == QueueItemKind.comment)
            i.itemId: i.displayTextSnippet,
      },
      liveChatSnippets: {
        for (final i in items)
          if (i.itemType == QueueItemKind.liveChat)
            i.itemId: i.displayTextSnippet,
      },
    );
  }

  Set<String> get commentIds => commentSnippets.keys.toSet();
  Set<String> get liveChatIds => liveChatSnippets.keys.toSet();
  Set<String> get allIds => {...commentIds, ...liveChatIds};
  int get count => commentSnippets.length + liveChatSnippets.length;
  bool get isEmpty => count == 0;

  /// Live chats with empty text may be membership events or already-deleted
  /// messages, so deleting them may fail.
  int get possibleMembershipEventCount => liveChatSnippets.values
      .where((text) => text == null || text.trim().isEmpty)
      .length;
}
