import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/adaptive_action_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletable_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_scope_dialog.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../../application/cross_channel_search_providers.dart';
import '../../application/selection_providers.dart';

/// The row above the channel list: how many channels or matches there are,
/// and buttons to select or queue items for deletion.
class ChannelListHeader extends ConsumerWidget {
  final String query;
  final int channelCount;
  final int matchCount;

  const ChannelListHeader({
    super.key,
    required this.query,
    required this.channelCount,
    required this.matchCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searching = query.isNotEmpty;
    final deletableMatches = searching
        ? ref.watch(crossChannelDeletableItemsProvider).length
        : 0;
    final selectionMode = selectionModeProvider();
    final selecting = ref.watch(selectionMode);

    final buttons = [
      if (searching && !selecting)
        AdaptiveActionButton(
          icon: Icons.checklist,
          label: 'Select',
          emphasis: ActionEmphasis.outlined,
          onPressed: deletableMatches > 0
              ? () => ref.read(selectionMode.notifier).enter()
              : null,
        ),
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
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Too narrow for the count beside the buttons: drop it and let the
          // buttons wrap.
          if (constraints.maxWidth < _countMinWidth) {
            return Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: buttons,
            );
          }
          return Row(
            children: [
              Expanded(
                child: Text(
                  searching
                      ? formatCount(
                          matchCount,
                          'matching comment or live chat',
                          plural: 'matching comments and live chats',
                        )
                      : formatCount(channelCount, 'channel'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final (i, button) in buttons.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                button,
              ],
            ],
          );
        },
      ),
    );
  }

  static const _countMinWidth = 200.0;

  void _queue(BuildContext context, WidgetRef ref) {
    final skipIds = ref.read(excludedFromDeletionIdsProvider);

    queueWithScopeDialog(context, ref, [
      if (query.isNotEmpty)
        QueueScope(
          icon: Icons.search,
          title: 'Matching “$query”',
          targets: DeletionTargets.of(
            ref.read(crossChannelDeletableItemsProvider).map((r) => r.item),
          ),
        ),
      QueueScope(
        icon: Icons.comment_outlined,
        title: 'All comments on YouTube',
        targets: deletableTargets(
          ref.read(allInteractionsProvider(QueueItemKind.comment)),
          skipIds: skipIds,
        ),
        describeCount: QueueScope.describeComments,
      ),
      QueueScope(
        icon: Icons.chat_bubble_outline,
        title: 'All live chats on YouTube',
        targets: deletableTargets(
          ref.read(allInteractionsProvider(QueueItemKind.liveChat)),
          skipIds: skipIds,
        ),
        describeCount: QueueScope.describeLiveChats,
      ),
    ]);
  }
}
