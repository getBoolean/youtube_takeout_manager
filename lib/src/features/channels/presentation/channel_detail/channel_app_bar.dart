import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/select_all_toggle_button.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';

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

/// "N selected", counting only this channel's comments and live chats.
class ChannelSelectionTitle extends ConsumerWidget {
  final String channelId;

  const ChannelSelectionTitle({super.key, required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(deletionSetProvider);
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final count =
        comments.where((c) => selected.contains(c.commentId)).length +
        liveChats.where((c) => selected.contains(c.liveChatId)).length;
    return Text('$count selected');
  }
}

/// Selects or deselects every item in the channel that can still be deleted.
class ChannelSelectAllAction extends ConsumerWidget {
  final String channelId;

  const ChannelSelectAllAction({super.key, required this.channelId});

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
