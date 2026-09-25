import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../domain/deletion_targets.dart';

/// [comments] and [liveChats] as deletion targets, leaving out the IDs in
/// [skipCommentIds] and [skipLiveChatIds] (e.g. ones already deleted, queued
/// or failed).
DeletionTargets deletableTargets({
  Iterable<Comment> comments = const [],
  Iterable<LiveChat> liveChats = const [],
  Set<String> skipCommentIds = const {},
  Set<String> skipLiveChatIds = const {},
}) {
  return DeletionTargets(
    commentSnippets: {
      for (final c in comments)
        if (!skipCommentIds.contains(c.commentId)) c.commentId: c.displayText,
    },
    liveChatSnippets: {
      for (final c in liveChats)
        if (!skipLiveChatIds.contains(c.liveChatId))
          c.liveChatId: c.displayText,
    },
  );
}
