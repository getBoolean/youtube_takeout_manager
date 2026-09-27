import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/deletion_service.dart';
import '../domain/deletion_targets.dart';
import 'confirm_local_removal_dialog.dart';
import 'queue_panel/deletion_queue_sheets.dart';
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

  final queued = await ref
      .read(deletionServiceProvider.notifier)
      .queue(targets);
  if (!queued) return false;
  if (!context.mounted) return true;
  showQueuedForDeletionSnackBar(
    context,
    message: Intl.plural(
      targets.count,
      one: '1 item added to the deletion queue',
      other: '${targets.count} items added to the deletion queue',
    ),
    onShow: deletionQueueOpener(context, ref),
  );
  return true;
}

/// Asks the user to confirm removing items from the on-device list only (no
/// YouTube deletion). Used for items already deleted outside the app. Returns
/// true if the items were removed.
Future<bool> confirmLocalRemoval(
  BuildContext context,
  WidgetRef ref,
  DeletionTargets targets,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmLocalRemovalDialog(count: targets.count),
  );
  if (confirmed != true) return false;

  await ref.read(deletionServiceProvider.notifier).removeLocally(targets);
  return true;
}
