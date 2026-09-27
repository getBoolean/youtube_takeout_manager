import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_names.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_shortcode.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/searchable_comment_text.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../domain/search_result_item.dart';
import 'channel_providers.dart';

part 'cross_channel_search_providers.g.dart';

/// Comments + live chats across every channel whose display text contains the
/// current [channelSearchQueryProvider] value, sorted newest first. Excludes
/// items already persisted as deleted. Empty when the query is empty.
@riverpod
List<SearchResultItem> crossChannelSearchItems(Ref ref) {
  final query = ref.watch(channelSearchQueryProvider);
  if (query.isEmpty) return const [];
  final folded = foldForSearch(normalizeEmojiQuery(query));
  final names = ref.watch(emojiNamesByKeyProvider);
  final emojiNames = queryMentionsEmoji(query);
  final deletedIds = ref.watch(deletedIdsProvider).value ?? const {};

  final results = <SearchResultItem>[];
  for (final kind in QueueItemKind.values) {
    final deleted = deletedIds[kind] ?? const {};
    ref.watch(interactionsByChannelProvider(kind)).forEach((channelId, items) {
      for (final item in items) {
        if (deleted.contains(item.id)) continue;
        if (foldForSearch(
          searchableCommentText(item.rawText, names, emojiNames: emojiNames),
        ).contains(folded)) {
          results.add(SearchResultItem(item, channelId: channelId));
        }
      }
    });
  }

  results.sort((a, b) => b.item.createdAt.compareTo(a.item.createdAt));
  return results;
}

/// Subset of [crossChannelSearchItemsProvider] that is eligible for bulk
/// deletion — strips items already in the deletion queue (pending/in-progress)
/// or currently failed.
@riverpod
List<SearchResultItem> crossChannelDeletableItems(Ref ref) {
  final items = ref.watch(crossChannelSearchItemsProvider);
  if (items.isEmpty) return const [];

  final excluded = ref.watch(excludedFromDeletionIdsProvider);
  return [
    for (final result in items)
      if (!(excluded[result.item.kind]?.contains(result.item.id) ?? false))
        result,
  ];
}
