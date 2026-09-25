import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/adaptive_action_button.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletable_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_scope_dialog.dart';
import 'package:youtube_takeout_manager/src/features/export/presentation/export_sheet.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/channel_providers.dart';
import '../../application/grouped_providers.dart';

/// The row above a channel's lists: open it on YouTube, export it, and
/// select or queue its items for deletion.
class ChannelActionsHeader extends ConsumerWidget {
  final String channelId;
  final ValueNotifier<bool> selectionMode;

  const ChannelActionsHeader({
    super.key,
    required this.channelId,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItems =
        ref.watch(
          channelCommentsProvider(channelId).select((l) => l.isNotEmpty),
        ) ||
        ref.watch(
          channelLiveChatsProvider(channelId).select((l) => l.isNotEmpty),
        );
    final matchCount = _deletableMatches(ref).count;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          AdaptiveActionButton(
            icon: Icons.open_in_new,
            label: 'Open on YouTube',
            onPressed: () => _openOnYouTube(ref),
          ),
          AdaptiveActionButton(
            icon: Icons.file_download_outlined,
            label: 'Export',
            onPressed: hasItems ? () => _export(context, ref) : null,
          ),
          const Spacer(),
          if (!selectionMode.value) ...[
            AdaptiveActionButton(
              icon: Icons.checklist,
              label: 'Select',
              emphasis: ActionEmphasis.outlined,
              onPressed: hasItems ? () => selectionMode.value = true : null,
            ),
            const SizedBox(width: 8),
          ],
          AdaptiveActionButton(
            icon: Icons.playlist_add,
            label: matchCount > 0
                ? Intl.plural(
                    matchCount,
                    one: 'Queue 1 match…',
                    other: 'Queue $matchCount matches…',
                  )
                : 'Queue…',
            emphasis: ActionEmphasis.tonal,
            onPressed: hasItems ? () => _queue(context, ref) : null,
          ),
        ],
      ),
    );
  }

  /// Search matches not yet deleted, queued or failed. Empty when there's no
  /// search.
  DeletionTargets _deletableMatches(WidgetRef ref) => deletableTargets(
    comments: ref.watch(filteredSearchCommentsProvider(channelId)),
    liveChats: ref.watch(filteredSearchLiveChatsProvider(channelId)),
    skipCommentIds: ref.watch(excludedFromDeletionCommentIdsProvider),
    skipLiveChatIds: ref.watch(excludedFromDeletionLiveChatIdsProvider),
  );

  void _openOnYouTube(WidgetRef ref) {
    final url =
        ref.read(channelByIdProvider(channelId))?.channelUrl ??
        'https://www.youtube.com/channel/$channelId';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _export(BuildContext context, WidgetRef ref) {
    showExportSheet(
      context,
      ref,
      channelId: channelId,
      channelName: _channelName(ref),
      comments: ref.read(channelCommentsProvider(channelId)),
      liveChats: ref.read(channelLiveChatsProvider(channelId)),
    );
  }

  void _queue(BuildContext context, WidgetRef ref) {
    final query = ref.read(channelContentSearchQueryProvider);
    final channelName = _channelName(ref);
    final comments = ref.read(channelCommentsProvider(channelId));
    final liveChats = ref.read(channelLiveChatsProvider(channelId));
    final skipCommentIds = ref.read(excludedFromDeletionCommentIdsProvider);
    final skipLiveChatIds = ref.read(excludedFromDeletionLiveChatIdsProvider);

    queueWithScopeDialog(context, ref, [
      if (query.isNotEmpty)
        QueueScope(
          icon: Icons.search,
          title: 'Matching “$query”',
          targets: deletableTargets(
            comments: ref.read(filteredSearchCommentsProvider(channelId)),
            liveChats: ref.read(filteredSearchLiveChatsProvider(channelId)),
            skipCommentIds: skipCommentIds,
            skipLiveChatIds: skipLiveChatIds,
          ),
        ),
      if (comments.isNotEmpty)
        QueueScope(
          icon: Icons.comment_outlined,
          title: 'All comments in $channelName',
          targets: deletableTargets(
            comments: comments,
            skipCommentIds: skipCommentIds,
          ),
          describeCount: QueueScope.describeComments,
        ),
      if (liveChats.isNotEmpty)
        QueueScope(
          icon: Icons.chat_bubble_outline,
          title: 'All live chats in $channelName',
          targets: deletableTargets(
            liveChats: liveChats,
            skipLiveChatIds: skipLiveChatIds,
          ),
          describeCount: QueueScope.describeLiveChats,
        ),
    ]);
  }

  String _channelName(WidgetRef ref) =>
      ref.read(channelByIdProvider(channelId))?.channelTitle ??
      'Unknown Channel';
}
