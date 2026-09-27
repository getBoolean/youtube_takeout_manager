import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'deletion_queue_item.dart';

/// Comments and live chats to delete from YouTube, keyed by ID with the text
/// snippet shown in the deletion queue.
class DeletionTargets {
  final Map<String, String?> commentSnippets;
  final Map<String, String?> liveChatSnippets;

  const DeletionTargets({
    this.commentSnippets = const {},
    this.liveChatSnippets = const {},
  });

  /// [items], each under its kind with its text.
  factory DeletionTargets.of(Iterable<Interaction> items) {
    return DeletionTargets(
      commentSnippets: {
        for (final i in items)
          if (i.kind == QueueItemKind.comment) i.id: i.displayText,
      },
      liveChatSnippets: {
        for (final i in items)
          if (i.kind == QueueItemKind.liveChat) i.id: i.displayText,
      },
    );
  }

  /// Items known only by ID, listed under their kind.
  factory DeletionTargets.ids(Map<QueueItemKind, Iterable<String>> idsByKind) {
    return DeletionTargets(
      commentSnippets: {
        for (final id in idsByKind[QueueItemKind.comment] ?? const <String>[])
          id: null,
      },
      liveChatSnippets: {
        for (final id in idsByKind[QueueItemKind.liveChat] ?? const <String>[])
          id: null,
      },
    );
  }

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

  /// The IDs of [kind]'s targets.
  Set<String> idsOf(QueueItemKind kind) => switch (kind) {
    QueueItemKind.comment => commentIds,
    QueueItemKind.liveChat => liveChatIds,
  };

  /// These targets, keeping only [ids].
  DeletionTargets only(Set<String> ids) => DeletionTargets(
    commentSnippets: {
      for (final MapEntry(:key, :value) in commentSnippets.entries)
        if (ids.contains(key)) key: value,
    },
    liveChatSnippets: {
      for (final MapEntry(:key, :value) in liveChatSnippets.entries)
        if (ids.contains(key)) key: value,
    },
  );

  /// How many of these live chats have no text in [liveChats], the
  /// takeout's. They may be membership events or already-deleted messages,
  /// so deleting them may fail. Goes by the takeout's full text, since the
  /// queue's snippet is shortened or missing.
  int possibleMembershipEventsIn(Iterable<Interaction> liveChats) => liveChats
      .where(
        (c) =>
            c.kind == QueueItemKind.liveChat &&
            liveChatSnippets.containsKey(c.id) &&
            c.rawText.trim().isEmpty,
      )
      .length;
}
