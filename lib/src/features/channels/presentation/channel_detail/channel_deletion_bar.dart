import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';

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
    final selectedIds = ref.watch(deletionSetProvider);

    return SelectionActionBar(
      selection: DeletionTargets.of([
        for (final kind in QueueItemKind.values)
          for (final item in ref.watch(
            channelInteractionsProvider(kind, channelId),
          ))
            if (selectedIds.contains(item.id)) item,
      ]),
      onExitSelection: () {
        selectionMode.value = false;
        ref.read(deletionSetProvider.notifier).clear();
      },
    );
  }
}
