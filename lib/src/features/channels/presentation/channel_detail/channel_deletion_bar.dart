import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';

class ChannelDeletionBar extends ConsumerWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;

  const ChannelDeletionBar({
    super.key,
    required this.channelId,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(channelCommentsProvider(channelId));
    final liveChats = ref.watch(channelLiveChatsProvider(channelId));
    final selectedIds = ref.watch(deletionSetProvider);

    return SelectionActionBar(
      selection: DeletionTargets(
        commentSnippets: {
          for (final c in comments)
            if (selectedIds.contains(c.commentId)) c.commentId: c.displayText,
        },
        liveChatSnippets: {
          for (final c in liveChats)
            if (selectedIds.contains(c.liveChatId)) c.liveChatId: c.displayText,
        },
      ),
      onExitSelection: () {
        selectionMode.value = false;
        ref.read(deletionSetProvider.notifier).clear();
      },
    );
  }
}
