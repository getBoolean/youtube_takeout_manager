import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/adaptive_action_button.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletable_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_scope_dialog.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import '../../application/cross_channel_search_providers.dart';
import 'cross_channel_deletion_bar.dart';

/// The row above the channel list: how many channels or matches there are,
/// and buttons to select or queue items for deletion.
class ChannelListHeader extends ConsumerWidget {
  final String query;
  final int channelCount;
  final int matchCount;
  final ValueNotifier<bool> selectionMode;

  const ChannelListHeader({
    super.key,
    required this.query,
    required this.channelCount,
    required this.matchCount,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searching = query.isNotEmpty;
    final deletableMatches = searching
        ? ref.watch(crossChannelDeletableItemsProvider).length
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              searching
                  ? Intl.plural(
                      matchCount,
                      one: '1 matching comment or live chat',
                      other: '$matchCount matching comments and live chats',
                    )
                  : Intl.plural(
                      channelCount,
                      one: '1 channel',
                      other: '$channelCount channels',
                    ),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (searching && !selectionMode.value) ...[
            AdaptiveActionButton(
              icon: Icons.checklist,
              label: 'Select',
              emphasis: ActionEmphasis.outlined,
              onPressed: deletableMatches > 0
                  ? () => selectionMode.value = true
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          AdaptiveActionButton(
            icon: Icons.playlist_add,
            label: deletableMatches > 0
                ? Intl.plural(
                    deletableMatches,
                    one: 'Queue 1 match…',
                    other: 'Queue $deletableMatches matches…',
                  )
                : 'Queue…',
            emphasis: ActionEmphasis.tonal,
            onPressed: () => _queue(context, ref),
          ),
        ],
      ),
    );
  }

  void _queue(BuildContext context, WidgetRef ref) {
    final skipCommentIds = ref.read(excludedFromDeletionCommentIdsProvider);
    final skipLiveChatIds = ref.read(excludedFromDeletionLiveChatIdsProvider);

    queueWithScopeDialog(context, ref, [
      if (query.isNotEmpty)
        QueueScope(
          icon: Icons.search,
          title: 'Matching “$query”',
          targets: deletionTargetsOf(
            ref.read(crossChannelDeletableItemsProvider),
          ),
        ),
      QueueScope(
        icon: Icons.comment_outlined,
        title: 'All comments on YouTube',
        targets: deletableTargets(
          comments: ref.read(allCommentsProvider),
          skipCommentIds: skipCommentIds,
        ),
        describeCount: QueueScope.describeComments,
      ),
      QueueScope(
        icon: Icons.chat_bubble_outline,
        title: 'All live chats on YouTube',
        targets: deletableTargets(
          liveChats: ref.read(allLiveChatsProvider),
          skipLiveChatIds: skipLiveChatIds,
        ),
        describeCount: QueueScope.describeLiveChats,
      ),
    ]);
  }
}
