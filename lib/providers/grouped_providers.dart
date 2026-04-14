import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/comment.dart';
import '../models/live_chat.dart';
import '../models/video_group.dart';
import 'comment_providers.dart';
import 'live_chat_providers.dart';

part 'grouped_providers.g.dart';

@riverpod
List<VideoGroup<Comment>> groupedChannelComments(
  Ref ref,
  String channelId,
) {
  final comments = ref.watch(channelCommentsProvider(channelId));
  final groups = <String, List<Comment>>{};

  for (final comment in comments) {
    final key = comment.videoId ?? (comment.postId != null ? 'post:${comment.postId}' : '_orphaned');
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
    final aOrder = a.groupType == GroupType.video ? 0 : a.groupType == GroupType.post ? 1 : 2;
    final bOrder = b.groupType == GroupType.video ? 0 : b.groupType == GroupType.post ? 1 : 2;
    if (aOrder != bOrder) return aOrder.compareTo(bOrder);
    return b.items.first.createdAt.compareTo(a.items.first.createdAt);
  });

  return result;
}

@riverpod
List<VideoGroup<LiveChat>> groupedChannelLiveChats(
  Ref ref,
  String channelId,
) {
  final liveChats = ref.watch(channelLiveChatsProvider(channelId));
  final groups = <String, List<LiveChat>>{};

  for (final chat in liveChats) {
    final key = chat.videoId ?? '_orphaned';
    groups.putIfAbsent(key, () => []).add(chat);
  }

  final result = groups.entries.map((entry) {
    final type = entry.key == '_orphaned' ? GroupType.orphaned : GroupType.video;
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
