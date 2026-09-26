import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_status_bar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../../application/deletion_queue_counts.dart';
import '../../application/deletion_queue_notifier.dart';
import '../../application/deletion_processing.dart';
import '../../application/queue_items_by_channel.dart';
import '../../application/viewed_queue_items.dart';
import '../../domain/deletion_item_status.dart';
import '../../domain/deletion_queue_item.dart';
import '../deletion_method_picker.dart';
import '../deletion_queue_item_tile.dart';

enum _QueueFilter {
  all('All', null),
  waiting('Waiting', DeletionQueueCounts.waitingStatuses),
  failed('Failed', DeletionQueueCounts.failedStatuses),
  done('Done', DeletionQueueCounts.doneStatuses);

  final String label;
  final Set<DeletionItemStatus>? statuses;

  const _QueueFilter(this.label, this.statuses);

  int countIn(DeletionQueueCounts counts) => switch (this) {
    all => counts.total,
    waiting => counts.waiting,
    failed => counts.failed,
    done => counts.done,
  };
}

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
  var _filter = _QueueFilter.all;

  /// Items the user has tapped remove on but whose exit animation is still
  /// playing. Kept so the tile stays rendered as the animation reverses; the
  /// actual provider removal happens when the animation ends.
  final Set<String> _removingIds = {};

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(deletionQueueProvider);
    final items = ref.watch(viewedQueueItemsProvider);
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
            _Header(count: counts.total, action: widget.headerAction),
            // The filters scroll with the list, so wrapped or large-text
            // chips can't squeeze it out.
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (counts.total > 0)
                    SliverToBoxAdapter(child: _buildFilters(counts)),
                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  if (unassigned > 0)
                    SliverToBoxAdapter(
                      child: _UnassignedNotice(count: unassigned),
                    ),
                  ...queueAsync.when(
                    loading: () => [fill(const CircularProgressIndicator())],
                    error: (e, _) => [fill(Text('Error: $e'))],
                    data: (_) => items.isEmpty
                        ? [fill(const _EmptyQueue())]
                        : _buildListSlivers(items, fill),
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
              child: SingleChildScrollView(child: _Footer(counts: counts)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(DeletionQueueCounts counts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final filter in _QueueFilter.values)
            ChoiceChip(
              // The name gives way before the count when narrow.
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${filter.label} ',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedCountText(filter.countIn(counts)),
                ],
              ),
              selected: _filter == filter,
              onSelected: (_) => setState(() => _filter = filter),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildListSlivers(
    List<DeletionQueueItem> items,
    Widget Function(Widget child) fill,
  ) {
    final statuses = _filter.statuses;
    final visible = statuses == null
        ? items
        : [
            for (final item in items)
              if (statuses.contains(item.status)) item,
          ];
    if (visible.isEmpty) {
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

    final channelsById = {
      for (final c in ref.watch(channelsProvider)) c.channelId: c,
    };
    final groups = groupQueueItemsByChannel(
      visible,
      channelIds: ref.watch(queuedItemChannelIdsProvider),
      channelName: (id) => channelsById[id]?.channelTitle ?? id,
      firstChannelId: widget.currentChannelId,
    );
    final rows = <Object>[
      for (final group in groups) ...[group, ...group.items],
    ];

    return [
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is QueueChannelGroup) {
            return _ChannelGroupHeader(
              key: ValueKey('group:${row.channelId}'),
              channel: channelsById[row.channelId],
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
        onRemove: item.status != DeletionItemStatus.inProgress
            ? () {
                if (_removingIds.contains(item.id)) return;
                setState(() => _removingIds.add(item.id));
              }
            : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final Widget? action;

  const _Header({required this.count, required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // App bar height, so the title lines up with the screen's beside it.
    return SizedBox(
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
        child: Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Deletion queue', style: theme.textTheme.titleMedium),
            ),
            if (count > 0)
              AnimatedCountText(
                count,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 4),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// Items queued before their channel was saved that the loaded takeout
/// doesn't have. They wait, undeleted, for the takeout they came from.
class _UnassignedNotice extends ConsumerWidget {
  final int count;

  const _UnassignedNotice({required this.count});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                Intl.plural(
                  count,
                  one:
                      "1 item queued before channels were tracked isn't in "
                      "this takeout. It'll show when you view the takeout it "
                      'came from.',
                  other:
                      "$count items queued before channels were tracked aren't "
                      "in this takeout. They'll show when you view the "
                      'takeout they came from.',
                ),
                style: theme.textTheme.bodySmall,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => ref
                      .read(deletionQueueProvider.notifier)
                      .removeUnassigned(),
                  child: Text(
                    count == 1 ? 'Remove it' : 'Remove them',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add_check,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Nothing queued', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Use Select or Queue… to add items.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelGroupHeader extends StatelessWidget {
  final Channel? channel;
  final int count;

  const _ChannelGroupHeader({
    super.key,
    required this.channel,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = channel?.channelTitle ?? 'Unknown channel';
    final thumbnailUrl = channel?.thumbnailUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: thumbnailUrl != null
                ? ClipOval(
                    child: Image.network(
                      thumbnailUrl,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    ),
                  )
                : Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 11,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.labelLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  final DeletionQueueCounts counts;

  const _Footer({required this.counts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isAuthenticatedProvider);
    final processing = ref.watch(deletionProcessingProvider);
    final notifier = ref.read(deletionQueueProvider.notifier);
    final channelId = ref.watch(viewedChannelIdProvider);
    final running = processing != DeletionProcessingState.idle;

    final buttons = [
      if (running)
        FilledButton.tonalIcon(
          onPressed: processing == DeletionProcessingState.running
              ? ref.read(deletionProcessingProvider.notifier).pauseProcessing
              : null,
          icon: const Icon(Icons.pause),
          label: Text(
            processing == DeletionProcessingState.running
                ? 'Pause'
                : 'Pausing…',
            textAlign: TextAlign.center,
          ),
        )
      else if (counts.waiting > 0)
        FilledButton.icon(
          onPressed: () => deleteQueuedItems(context, ref),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(
            Intl.plural(
              counts.waiting,
              one: 'Delete 1…',
              other: 'Delete ${counts.waiting}…',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      if (counts.failed > 0 && !running)
        TextButton.icon(
          onPressed: channelId == null
              ? null
              : () => notifier.retryFailed(channelId: channelId),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry failed', textAlign: TextAlign.center),
        ),
      if (counts.done > 0)
        TextButton.icon(
          onPressed: channelId == null
              ? null
              : () => notifier.clearCompleted(channelId: channelId),
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear done', textAlign: TextAlign.center),
        ),
    ];
    if (!signedIn && buttons.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (signedIn)
                const QuotaStatusBar(compact: true, padding: EdgeInsets.zero),
              if (signedIn && buttons.isNotEmpty) const SizedBox(height: 12),
              if (buttons.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: buttons),
            ],
          ),
        ),
      ),
    );
  }
}
