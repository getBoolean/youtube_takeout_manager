import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../domain/search_options_state.dart';
import '../domain/video_group.dart';
import 'channel_content_search_query.dart';
import 'search_options_providers.dart';

part 'grouped_providers.g.dart';

/// [kind]'s items on [channelId]'s videos, grouped by video.
@riverpod
List<VideoGroup<Interaction>> groupedChannelInteractions(
  Ref ref,
  QueueItemKind kind,
  String channelId,
) => groupByVideo(ref.watch(channelInteractionsProvider(kind, channelId)));

/// Resolves the display title of a group — mirrors `VideoGroupHeader._resolveTitle`
/// so search can match against what the user actually sees in group headers.
String _resolveGroupTitle(VideoGroup group, Map<String, Video> videoMap) {
  switch (group.groupType) {
    case GroupType.video:
      return videoMap[group.groupKey]?.title ?? 'Video: ${group.groupKey}';
    case GroupType.post:
      final postId = group.groupKey.replaceFirst('post:', '');
      return 'Community Post: $postId';
    case GroupType.orphaned:
      return 'Other';
  }
}

/// The groups of [groupedChannelInteractionsProvider] that match the channel
/// search: by group title, or by the text of their items.
@riverpod
List<VideoGroup<Interaction>> filteredGroupedChannelInteractions(
  Ref ref,
  QueueItemKind kind,
  String channelId,
) {
  final groups = ref.watch(groupedChannelInteractionsProvider(kind, channelId));
  final query = ref.watch(channelContentSearchQueryProvider);
  if (query.isEmpty) return groups;
  final videoMap = ref.watch(videoMetadataProvider).value ?? const {};
  final options =
      ref.watch(searchOptionsProvider).value ?? const SearchOptionsState();
  final names = ref.watch(emojiNamesByKeyProvider);
  final emojiNames = queryMentionsEmoji(query);

  final folded = foldForSearch(normalizeEmojiQuery(query));
  final result = <VideoGroup<Interaction>>[];
  for (final group in groups) {
    if (options.matchGroupTitles) {
      final title = foldForSearch(_resolveGroupTitle(group, videoMap));
      if (title.contains(folded)) {
        result.add(group);
        continue;
      }
    }
    final matching = group.items
        .where(
          (item) => foldForSearch(
            searchableCommentText(item.rawText, names, emojiNames: emojiNames),
          ).contains(folded),
        )
        .toList();
    if (matching.isNotEmpty) {
      result.add(
        options.expandMatchedVideos
            ? group
            : VideoGroup<Interaction>(
                groupKey: group.groupKey,
                groupType: group.groupType,
                items: matching,
              ),
      );
    }
  }
  return result;
}

/// Flat list of [kind]'s items currently visible in search results,
/// excluding any already marked as deleted. Empty when the search query is
/// empty.
@riverpod
List<Interaction> filteredSearchInteractions(
  Ref ref,
  QueueItemKind kind,
  String channelId,
) {
  final query = ref.watch(channelContentSearchQueryProvider);
  if (query.isEmpty) return const [];
  final groups = ref.watch(
    filteredGroupedChannelInteractionsProvider(kind, channelId),
  );
  final deleted = ref.watch(deletedIdsProvider).value?[kind] ?? const {};
  return [
    for (final g in groups)
      for (final item in g.items)
        if (!deleted.contains(item.id)) item,
  ];
}
