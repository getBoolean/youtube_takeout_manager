import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_actions.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_queue_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/select_all_toggle_button.dart';
import 'package:youtube_takeout_manager/src/features/export/presentation/export_sheet.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../../application/channel_providers.dart';
import '../../application/grouped_providers.dart';

class ChannelTabLabel extends StatelessWidget {
  final String prefix;
  final int count;

  const ChannelTabLabel({super.key, required this.prefix, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Text('$prefix ('), AnimatedCountText(count), const Text(')')],
    );
  }
}

class ChannelTitle extends StatelessWidget {
  final String channelName;
  final String? thumbnailUrl;

  const ChannelTitle({super.key, required this.channelName, this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: thumbnailUrl != null
              ? ClipOval(
                  child: Image.network(
                    thumbnailUrl!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  ),
                )
              : Text(
                  channelName[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(channelName, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class ChannelAppBarActions extends ConsumerWidget {
  final String channelId;
  final String? channelUrl;
  final ValueNotifier<bool> selectionMode;

  const ChannelAppBarActions({
    super.key,
    required this.channelId,
    required this.channelUrl,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectionMode.value) {
      return _SelectAllAction(channelId: channelId);
    }

    final channel = ref.watch(channelByIdProvider(channelId));
    final channelName = channel?.channelTitle ?? 'Unknown Channel';
    final hasComments = ref.watch(
      channelCommentsProvider(channelId).select((l) => l.isNotEmpty),
    );
    final hasLiveChats = ref.watch(
      channelLiveChatsProvider(channelId).select((l) => l.isNotEmpty),
    );
    final matchingCommentCount = ref.watch(
      filteredSearchCommentsProvider(channelId).select((l) => l.length),
    );
    final matchingLiveChatCount = ref.watch(
      filteredSearchLiveChatsProvider(channelId).select((l) => l.length),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Open on YouTube',
          onPressed: () {
            final url =
                channelUrl ?? 'https://www.youtube.com/channel/$channelId';
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
        ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          tooltip: 'Export',
          onPressed: () => showExportSheet(
            context,
            ref,
            channelId: channelId,
            channelName: channelName,
            comments: ref.read(channelCommentsProvider(channelId)),
            liveChats: ref.read(channelLiveChatsProvider(channelId)),
          ),
        ),
        const DeletionQueueButton(),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'delete_all_comments':
              case 'delete_all_chats':
                _handleChannelDelete(
                  context,
                  ref,
                  value: value,
                  comments: ref.read(channelCommentsProvider(channelId)),
                  liveChats: ref.read(channelLiveChatsProvider(channelId)),
                  skipCommentIds: ref.read(
                    excludedFromDeletionCommentIdsProvider,
                  ),
                  skipLiveChatIds: ref.read(
                    excludedFromDeletionLiveChatIdsProvider,
                  ),
                );
              case 'delete_matching_comments':
                _handleDeleteSearchResults(
                  context,
                  ref,
                  isComments: true,
                  channelId: channelId,
                );
              case 'delete_matching_chats':
                _handleDeleteSearchResults(
                  context,
                  ref,
                  isComments: false,
                  channelId: channelId,
                );
            }
          },
          itemBuilder: (_) => [
            if (hasComments)
              const PopupMenuItem(
                value: 'delete_all_comments',
                child: Text('Delete All Comments from Channel'),
              ),
            if (hasLiveChats)
              const PopupMenuItem(
                value: 'delete_all_chats',
                child: Text('Delete All Live Chats from Channel'),
              ),
            if (matchingCommentCount > 0)
              PopupMenuItem(
                value: 'delete_matching_comments',
                child: Text(
                  Intl.plural(
                    matchingCommentCount,
                    one: 'Delete 1 matching comment',
                    other: 'Delete $matchingCommentCount matching comments',
                  ),
                ),
              ),
            if (matchingLiveChatCount > 0)
              PopupMenuItem(
                value: 'delete_matching_chats',
                child: Text(
                  Intl.plural(
                    matchingLiveChatCount,
                    one: 'Delete 1 matching live chat',
                    other: 'Delete $matchingLiveChatCount matching live chats',
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SelectAllAction extends ConsumerWidget {
  final String channelId;

  const _SelectAllAction({required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final skipCommentIds = ref.watch(excludedFromDeletionCommentIdsProvider);
    final skipLiveChatIds = ref.watch(excludedFromDeletionLiveChatIdsProvider);
    final selectableIds = {
      ...comments
          .where((c) => !skipCommentIds.contains(c.commentId))
          .map((c) => c.commentId),
      ...liveChats
          .where((c) => !skipLiveChatIds.contains(c.liveChatId))
          .map((c) => c.liveChatId),
    };
    return SelectAllToggleButton(selectableIds: selectableIds);
  }
}

void _handleChannelDelete(
  BuildContext context,
  WidgetRef ref, {
  required String value,
  required List<Comment> comments,
  required List<LiveChat> liveChats,
  required Set<String> skipCommentIds,
  required Set<String> skipLiveChatIds,
}) {
  deleteFromYouTube(
    context,
    ref,
    value == 'delete_all_comments'
        ? DeletionTargets(
            commentSnippets: {
              for (final c in comments)
                if (!skipCommentIds.contains(c.commentId))
                  c.commentId: c.displayText,
            },
          )
        : DeletionTargets(
            liveChatSnippets: {
              for (final c in liveChats)
                if (!skipLiveChatIds.contains(c.liveChatId))
                  c.liveChatId: c.displayText,
            },
          ),
  );
}

void _handleDeleteSearchResults(
  BuildContext context,
  WidgetRef ref, {
  required bool isComments,
  required String channelId,
}) {
  if (isComments) {
    final matches = ref.read(filteredSearchCommentsProvider(channelId));
    final skip = ref.read(excludedFromDeletionCommentIdsProvider);
    deleteFromYouTube(
      context,
      ref,
      DeletionTargets(
        commentSnippets: {
          for (final c in matches)
            if (!skip.contains(c.commentId)) c.commentId: c.displayText,
        },
      ),
    );
  } else {
    final matches = ref.read(filteredSearchLiveChatsProvider(channelId));
    final skip = ref.read(excludedFromDeletionLiveChatIdsProvider);
    deleteFromYouTube(
      context,
      ref,
      DeletionTargets(
        liveChatSnippets: {
          for (final c in matches)
            if (!skip.contains(c.liveChatId)) c.liveChatId: c.displayText,
        },
      ),
    );
  }
}
