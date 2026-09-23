import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/deletion_method.dart';
import '../models/deletion_targets.dart';
import '../providers/auth_providers.dart';
import '../providers/deleted_ids_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/script_deletion_provider.dart';
import '../router/app_router.dart';
import 'deletion_method_picker.dart';
import 'queue_snackbar.dart';

/// Asks the user how to delete [targets] from YouTube and carries out their
/// choice. Returns true if the targets were handed off for deletion, or false
/// if the user cancelled.
Future<bool> deleteFromYouTube(
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

  final method = await pickDeletionMethod(
    context,
    title: Intl.plural(
      targets.count,
      one: 'Delete 1 item',
      other: 'Delete ${targets.count} items',
    ),
    itemCount: targets.count,
    possibleMembershipEventCount: targets.possibleMembershipEventCount,
    youtubeApiAvailable: ref.read(isAuthenticatedProvider),
  );
  if (method == null || !context.mounted) return false;

  switch (method) {
    case DeletionMethod.addToQueue:
      await _addToQueue(context, ref, targets);
    case DeletionMethod.myActivityScript:
      openMyActivityScript(context, ref, targets.allIds);
    case DeletionMethod.youtubeApi:
      await _deleteNowViaYoutubeApi(context, ref, targets);
  }
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

Future<void> _addToQueue(
  BuildContext context,
  WidgetRef ref,
  DeletionTargets targets,
) async {
  await ref.read(deletionQueueProvider.notifier).enqueue(targets);
  if (!context.mounted) return;
  showQueuedForDeletionSnackBar(
    context,
    ref,
    message: Intl.plural(
      targets.count,
      one: '1 item queued for deletion',
      other: '${targets.count} items queued for deletion',
    ),
  );
}

Future<void> _deleteNowViaYoutubeApi(
  BuildContext context,
  WidgetRef ref,
  DeletionTargets targets,
) async {
  final queue = ref.read(deletionQueueProvider.notifier);
  await queue.enqueue(targets);
  queue.startYoutubeApiProcessing();
  if (!context.mounted) return;
  showQueuedForDeletionSnackBar(
    context,
    ref,
    message: Intl.plural(
      targets.count,
      one: 'Deleting 1 item via YouTube API',
      other: 'Deleting ${targets.count} items via YouTube API',
    ),
  );
}

/// Asks the user to confirm removing items from the on-device list only (no
/// YouTube deletion). Used for items already deleted outside the app. Returns
/// true if the items were removed.
Future<bool> confirmLocalRemoval(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> commentIds,
  required Set<String> liveChatIds,
}) async {
  final total = commentIds.length + liveChatIds.length;
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

  if (commentIds.isNotEmpty) {
    await ref.read(deletedCommentIdsProvider.notifier).markDeleted(commentIds);
  }
  if (liveChatIds.isNotEmpty) {
    await ref
        .read(deletedLiveChatIdsProvider.notifier)
        .markDeleted(liveChatIds);
  }
  return true;
}
