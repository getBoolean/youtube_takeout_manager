import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../application/deleted_ids_providers.dart';
import '../application/deletion_queue_notifier.dart';
import '../application/script_deletion_ids.dart';
import '../domain/deletion_targets.dart';
import 'queue_snackbar.dart';

/// Adds [targets] to the deletion queue, where the user later picks how to
/// delete them. Returns false if there was nothing to queue.
Future<bool> queueForDeletion(
  BuildContext context,
  WidgetRef ref,
  DeletionTargets targets,
) async {
  if (targets.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No items to delete')));
    return false;
  }

  // Everything on screen is the viewed channel's, so it wrote them.
  final channelId = ref.read(viewedChannelIdProvider);
  if (channelId == null) return false;
  await ref
      .read(deletionQueueProvider.notifier)
      .enqueue(targets, authorChannelId: channelId);
  if (!context.mounted) return true;
  showQueuedForDeletionSnackBar(
    context,
    ref,
    message: Intl.plural(
      targets.count,
      one: '1 item added to the deletion queue',
      other: '${targets.count} items added to the deletion queue',
    ),
  );
  return true;
}

/// Opens the My Activity script screen for [ids].
void openMyActivityScript(
  BuildContext context,
  WidgetRef ref,
  Set<String> ids,
) {
  ref.read(scriptDeletionIdsProvider.notifier).set(ids);
  context.router.push(const ScriptDeletionRoute());
}

/// Asks the user to confirm removing items from the on-device list only (no
/// YouTube deletion). Used for items already deleted outside the app. Returns
/// true if the items were removed.
Future<bool> confirmLocalRemoval(
  BuildContext context,
  WidgetRef ref,
  DeletionTargets targets,
) async {
  final total = targets.count;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove Items'),
      content: Text(
        '${Intl.plural(total, one: 'Remove 1 item', other: 'Remove $total items')} from the list?\n\n'
        'Use this for items you already deleted manually outside the app. '
        'This does not delete them from YouTube.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  await ref.read(deletedIdsProvider.notifier).markDeleted(targets);
  return true;
}
