import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/adaptive_action_button.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletable_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_scope_dialog.dart';
import 'package:youtube_takeout_manager/src/features/export/presentation/export_sheet.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/channel_providers.dart';
import '../../application/grouped_providers.dart';

/// The row above a channel's lists: export it, and select or queue its items
/// for deletion.
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
    final hasItems = QueueItemKind.values.any(
      (kind) => ref.watch(
        channelInteractionsProvider(
          kind,
          channelId,
        ).select((l) => l.isNotEmpty),
      ),
    );
    final matchCount = _deletableMatches(ref).count;

    // Wraps, rather than overflowing, when the window is too narrow for one
    // row.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          AdaptiveActionButton(
            icon: Icons.file_download_outlined,
            label: 'Export',
            onPressed: hasItems ? () => _export(context, ref) : null,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (!selectionMode.value)
                AdaptiveActionButton(
                  icon: Icons.checklist,
                  label: 'Select',
                  emphasis: ActionEmphasis.outlined,
                  onPressed: hasItems ? () => selectionMode.value = true : null,
                ),
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
        ],
      ),
    );
  }

  /// Search matches not yet deleted, queued or failed. Empty when there's no
  /// search.
  DeletionTargets _deletableMatches(WidgetRef ref) => deletableTargets([
    for (final kind in QueueItemKind.values)
      ...ref.watch(filteredSearchInteractionsProvider(kind, channelId)),
  ], skipIds: ref.watch(excludedFromDeletionIdsProvider));

  void _export(BuildContext context, WidgetRef ref) {
    showExportSheet(
      context,
      ref,
      channelId: channelId,
      channelName: _channelName(ref),
      comments: _itemsOf(ref, QueueItemKind.comment).cast<Comment>(),
      liveChats: _itemsOf(ref, QueueItemKind.liveChat).cast<LiveChat>(),
    );
  }

  void _queue(BuildContext context, WidgetRef ref) {
    final query = ref.read(channelContentSearchQueryProvider);
    final channelName = _channelName(ref);
    final comments = _itemsOf(ref, QueueItemKind.comment);
    final liveChats = _itemsOf(ref, QueueItemKind.liveChat);
    final skipIds = ref.read(excludedFromDeletionIdsProvider);

    queueWithScopeDialog(context, ref, [
      if (query.isNotEmpty)
        QueueScope(
          icon: Icons.search,
          title: 'Matching “$query”',
          targets: deletableTargets([
            for (final kind in QueueItemKind.values)
              ...ref.read(filteredSearchInteractionsProvider(kind, channelId)),
          ], skipIds: skipIds),
        ),
      if (comments.isNotEmpty)
        QueueScope(
          icon: Icons.comment_outlined,
          title: 'All comments in $channelName',
          targets: deletableTargets(comments, skipIds: skipIds),
          describeCount: QueueScope.describeComments,
        ),
      if (liveChats.isNotEmpty)
        QueueScope(
          icon: Icons.chat_bubble_outline,
          title: 'All live chats in $channelName',
          targets: deletableTargets(liveChats, skipIds: skipIds),
          describeCount: QueueScope.describeLiveChats,
        ),
    ]);
  }

  List<Interaction> _itemsOf(WidgetRef ref, QueueItemKind kind) =>
      ref.read(channelInteractionsProvider(kind, channelId));

  String _channelName(WidgetRef ref) =>
      ref.read(channelByIdProvider(channelId))?.channelTitle ??
      'Unknown Channel';
}
