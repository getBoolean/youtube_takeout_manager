import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/comment.dart';
import '../models/live_chat.dart';
import '../models/video.dart';
import '../models/video_group.dart';
import '../models/search_options_state.dart';
import '../utils/comment_text_parser.dart';
import 'comment_providers.dart';
import 'deleted_ids_providers.dart';
import 'emoji_providers.dart';
import 'live_chat_providers.dart';
import 'search_options_providers.dart';
import 'video_providers.dart';

part 'grouped_providers.g.dart';

@riverpod
List<VideoGroup<Comment>> groupedChannelComments(Ref ref, String channelId) {
  final comments = ref.watch(channelCommentsProvider(channelId));
  final groups = <String, List<Comment>>{};

  for (final comment in comments) {
    final key =
        comment.videoId ??
        (comment.postId != null ? 'post:${comment.postId}' : '_orphaned');
    groups.putIfAbsent(key, () => []).add(comment);
  }

  final result = groups.entries.map((entry) {
    final GroupType type;
    if (entry.key == '_orphaned') {
      type = GroupType.orphaned;
    } else if (entry.key.startsWith('post:')) {
      type = GroupType.post;
    } else {
      type = GroupType.video;
    }
    return VideoGroup<Comment>(
      groupKey: entry.key,
      groupType: type,
      items: entry.value,
    );
  }).toList();

  // Sort: video groups by most recent item first, then posts, then orphaned
  result.sort((a, b) {
    final aOrder = a.groupType == GroupType.video
        ? 0
        : a.groupType == GroupType.post
        ? 1
        : 2;
    final bOrder = b.groupType == GroupType.video
        ? 0
        : b.groupType == GroupType.post
        ? 1
        : 2;
    if (aOrder != bOrder) return aOrder.compareTo(bOrder);
    return b.items.first.createdAt.compareTo(a.items.first.createdAt);
  });

  return result;
}

@riverpod
List<VideoGroup<LiveChat>> groupedChannelLiveChats(Ref ref, String channelId) {
  final liveChats = ref.watch(channelLiveChatsProvider(channelId));
  final groups = <String, List<LiveChat>>{};

  for (final chat in liveChats) {
    final key = chat.videoId ?? '_orphaned';
    groups.putIfAbsent(key, () => []).add(chat);
  }

  final result = groups.entries.map((entry) {
    final type = entry.key == '_orphaned'
        ? GroupType.orphaned
        : GroupType.video;
    return VideoGroup<LiveChat>(
      groupKey: entry.key,
      groupType: type,
      items: entry.value,
    );
  }).toList();

  result.sort((a, b) {
    if (a.groupType != b.groupType) {
      return a.groupType == GroupType.video ? -1 : 1;
    }
    return b.items.first.createdAt.compareTo(a.items.first.createdAt);
  });

  return result;
}

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

List<VideoGroup<T>> _filterGroups<T>({
  required List<VideoGroup<T>> groups,
  required String query,
  required Map<String, Video> videoMap,
  required SearchOptionsState options,
  required String Function(T) extractText,
  required VideoGroup<T> Function(VideoGroup<T> group, List<T> items) rebuild,
}) {
  if (query.isEmpty) return groups;
  final lower = normalizeEmojiQuery(query).toLowerCase();
  final result = <VideoGroup<T>>[];
  for (final group in groups) {
    if (options.matchGroupTitles) {
      final title = _resolveGroupTitle(group, videoMap).toLowerCase();
      if (title.contains(lower)) {
        result.add(group);
        continue;
      }
    }
    final matching = group.items
        .where((item) => extractText(item).toLowerCase().contains(lower))
        .toList();
    if (matching.isNotEmpty) {
      result.add(
        options.expandMatchedVideos ? group : rebuild(group, matching),
      );
    }
  }
  return result;
}

@riverpod
List<VideoGroup<Comment>> filteredGroupedChannelComments(
  Ref ref,
  String channelId,
) {
  final groups = ref.watch(groupedChannelCommentsProvider(channelId));
  final query = ref.watch(commentSearchQueryProvider);
  final videoMap = ref.watch(videoMetadataProvider).value ?? const {};
  final options =
      ref.watch(searchOptionsProvider).value ?? const SearchOptionsState();
  final names = ref.watch(emojiNamesByKeyProvider);
  return _filterGroups<Comment>(
    groups: groups,
    query: query,
    videoMap: videoMap,
    options: options,
    extractText: (c) => searchableCommentText(c.rawCommentText, names),
    rebuild: (g, items) => VideoGroup<Comment>(
      groupKey: g.groupKey,
      groupType: g.groupType,
      items: items,
    ),
  );
}

@riverpod
List<VideoGroup<LiveChat>> filteredGroupedChannelLiveChats(
  Ref ref,
  String channelId,
) {
  final groups = ref.watch(groupedChannelLiveChatsProvider(channelId));
  final query = ref.watch(liveChatSearchQueryProvider);
  final videoMap = ref.watch(videoMetadataProvider).value ?? const {};
  final options =
      ref.watch(searchOptionsProvider).value ?? const SearchOptionsState();
  final names = ref.watch(emojiNamesByKeyProvider);
  return _filterGroups<LiveChat>(
    groups: groups,
    query: query,
    videoMap: videoMap,
    options: options,
    extractText: (c) => searchableCommentText(c.rawText, names),
    rebuild: (g, items) => VideoGroup<LiveChat>(
      groupKey: g.groupKey,
      groupType: g.groupType,
      items: items,
    ),
  );
}

/// Flat list of comments currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.
@riverpod
List<Comment> filteredSearchComments(Ref ref, String channelId) {
  final query = ref.watch(commentSearchQueryProvider);
  if (query.isEmpty) return const [];
  final groups = ref.watch(filteredGroupedChannelCommentsProvider(channelId));
  final deleted =
      ref.watch(deletedCommentIdsProvider).value ?? const <String>{};
  return [
    for (final g in groups)
      for (final c in g.items)
        if (!deleted.contains(c.commentId)) c,
  ];
}

/// Flat list of live chats currently visible in search results, excluding any
/// already marked as deleted. Empty when the search query is empty.
@riverpod
List<LiveChat> filteredSearchLiveChats(Ref ref, String channelId) {
  final query = ref.watch(liveChatSearchQueryProvider);
  if (query.isEmpty) return const [];
  final groups = ref.watch(filteredGroupedChannelLiveChatsProvider(channelId));
  final deleted =
      ref.watch(deletedLiveChatIdsProvider).value ?? const <String>{};
  return [
    for (final g in groups)
      for (final c in g.items)
        if (!deleted.contains(c.liveChatId)) c,
  ];
}
