import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/queue_item_kind.dart';
import '../models/search_result_item.dart';
import '../utils/comment_text_parser.dart';
import 'channel_providers.dart';
import 'comment_providers.dart';
import 'deleted_ids_providers.dart';
import 'emoji_providers.dart';
import 'live_chat_providers.dart';

part 'cross_channel_search_providers.g.dart';

/// Comments + live chats across every channel whose display text contains the
/// current [channelSearchQueryProvider] value, sorted newest first. Excludes
/// items already persisted as deleted. Empty when the query is empty.
@riverpod
List<SearchResultItem> crossChannelSearchItems(Ref ref) {
  final query = ref.watch(channelSearchQueryProvider);
  if (query.isEmpty) return const [];
  final lower = normalizeEmojiQuery(query).toLowerCase();
  final names = ref.watch(emojiNamesByKeyProvider);

  final commentsByChannel = ref.watch(commentsByChannelProvider);
  final liveChatsByChannel = ref.watch(liveChatsByChannelProvider);
  final deletedComments =
      ref.watch(deletedCommentIdsProvider).value ?? const <String>{};
  final deletedLiveChats =
      ref.watch(deletedLiveChatIdsProvider).value ?? const <String>{};

  final results = <SearchResultItem>[];

  commentsByChannel.forEach((channelId, comments) {
    for (final c in comments) {
      if (deletedComments.contains(c.commentId)) continue;
      if (searchableCommentText(
        c.rawCommentText,
        names,
      ).toLowerCase().contains(lower)) {
        results.add(CommentResult(c, channelId: channelId));
      }
    }
  });

  liveChatsByChannel.forEach((channelId, chats) {
    for (final chat in chats) {
      if (deletedLiveChats.contains(chat.liveChatId)) continue;
      if (searchableCommentText(
        chat.rawText,
        names,
      ).toLowerCase().contains(lower)) {
        results.add(LiveChatResult(chat, channelId: channelId));
      }
    }
  });

  results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return results;
}

/// Subset of [crossChannelSearchItemsProvider] that is eligible for bulk
/// deletion — strips items already in the deletion queue (pending/in-progress)
/// or currently failed.
@riverpod
List<SearchResultItem> crossChannelDeletableItems(Ref ref) {
  final items = ref.watch(crossChannelSearchItemsProvider);
  if (items.isEmpty) return const [];

  final queuedComments = ref.watch(queuedCommentIdsProvider);
  final failedComments = ref.watch(failedCommentIdsProvider);
  final queuedLiveChats = ref.watch(queuedLiveChatIdsProvider);
  final failedLiveChats = ref.watch(failedLiveChatIdsProvider);

  return [
    for (final item in items)
      if (item.kind == QueueItemKind.comment
          ? !queuedComments.contains(item.id) &&
                !failedComments.contains(item.id)
          : !queuedLiveChats.contains(item.id) &&
                !failedLiveChats.contains(item.id))
        item,
  ];
}
