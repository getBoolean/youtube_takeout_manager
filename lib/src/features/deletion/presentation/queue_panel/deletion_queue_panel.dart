import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/deletion_queue_groups.dart';
import '../../application/deletion_queue_counts.dart';
import '../../application/deletion_queue_filter.dart';
import '../../application/deletion_queue_notifier.dart';
import '../../application/queue_items_by_channel.dart';
import '../../application/viewed_queue_items.dart';
import '../../domain/deletion_queue_item.dart';
import '../deletion_queue_item_tile.dart';
import 'deletion_queue_filter_chips.dart';
import 'deletion_queue_footer.dart';
import 'deletion_queue_panel_header.dart';
import 'empty_deletion_queue.dart';
import 'queue_channel_group_header.dart';
import 'unassigned_queue_notice.dart';

/// The deletion queue grouped by channel, with controls to delete, pause,
/// retry and clear. Shown in a docked pane, a side sheet or a bottom sheet.
class DeletionQueuePanel extends ConsumerStatefulWidget {
  /// The channel on screen, whose items are listed first.
  final String? currentChannelId;

  /// The header's trailing button, e.g. to collapse or close the panel.
  final Widget? headerAction;

  const DeletionQueuePanel({
    super.key,
    this.currentChannelId,
    this.headerAction,
  });

  @override
  ConsumerState<DeletionQueuePanel> createState() => _DeletionQueuePanelState();
}

class _DeletionQueuePanelState extends ConsumerState<DeletionQueuePanel> {
  var _filter = DeletionQueueFilter.all;

  /// Items the user has tapped remove on but whose exit animation is still
  /// playing. Kept so the tile stays rendered as the animation reverses; the
  /// actual provider removal happens when the animation ends.
  final Set<String> _removingIds = {};

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(deletionQueueProvider);
    final hasItems = ref.watch(
      viewedQueueItemsProvider.select((items) => items.isNotEmpty),
    );
    final unassigned = ref.watch(unassignedQueueItemsProvider).length;
    final counts = ref.watch(deletionQueueCountsProvider);

    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: false, child: Center(child: child));

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DeletionQueuePanelHeader(
              count: counts.total,
              action: widget.headerAction,
            ),
            // The filters scroll with the list, so wrapped or large-text
            // chips can't squeeze it out.
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (counts.total > 0)
                    SliverToBoxAdapter(
                      child: DeletionQueueFilterChips(
                        counts: counts,
                        selected: _filter,
                        onSelected: (filter) =>
                            setState(() => _filter = filter),
                      ),
                    ),
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  if (unassigned > 0)
                    SliverToBoxAdapter(
                      child: UnassignedQueueNotice(count: unassigned),
                    ),
                  ...queueAsync.when(
                    loading: () => [fill(const CircularProgressIndicator())],
                    error: (e, _) => [fill(Text('Error: $e'))],
                    data: (_) => hasItems
                        ? _buildListSlivers(fill)
                        : [fill(const EmptyDeletionQueue())],
                  ),
                ],
              ),
            ),
            // At most half the panel, scrolling inside, for the same reason.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.hasBoundedHeight
                    ? constraints.maxHeight / 2
                    : double.infinity,
              ),
              child: SingleChildScrollView(
                child: DeletionQueueFooter(counts: counts),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListSlivers(Widget Function(Widget child) fill) {
    final groups = ref.watch(
      deletionQueueGroupsProvider(
        _filter,
        firstChannelId: widget.currentChannelId,
      ),
    );
    if (groups.isEmpty) {
      return [
        fill(
          Text(
            'No ${_filter.label.toLowerCase()} items',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    final rows = <Object>[
      for (final group in groups) ...[group, ...group.items],
    ];
    return [
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is QueueChannelGroup) {
            return QueueChannelGroupHeader(
              key: ValueKey('group:${row.channelId}'),
              channelId: row.channelId,
              count: row.items.length,
            );
          }
          return _buildItem(row as DeletionQueueItem);
        },
      ),
    ];
  }

  Widget _buildItem(DeletionQueueItem item) {
    final isRemoving = _removingIds.contains(item.id);
    final motion = premiumSpring(context);
    return Cue.onToggle(
      key: ValueKey(item.id),
      toggled: !isRemoving,
      motion: motion,
      reverseMotion: motion,
      acts: const [
        ClipAct.height(),
        OpacityAct.fadeIn(),
        SlideAct.x(from: 1.0),
      ],
      onEnd: (visible) {
        if (!visible && mounted && _removingIds.contains(item.id)) {
          ref.read(deletionQueueProvider.notifier).removeItem(item.id);
          setState(() => _removingIds.remove(item.id));
        }
      },
      child: DeletionQueueItemTile(
        item: item,
        onRemove: !item.status.isInProgress
            ? () {
                if (_removingIds.contains(item.id)) return;
                setState(() => _removingIds.add(item.id));
              }
            : null,
      ),
    );
  }
}
