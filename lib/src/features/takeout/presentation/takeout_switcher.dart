import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../application/takeout_selection_notifier.dart';
import '../domain/takeout_channel.dart';

/// Whether nothing is being deleted through the YouTube API. If something
/// is, explains that it has to stop first, offering to pause it, and returns
/// false: switching mid-deletion would leave it deleting a channel no longer
/// shown.
Future<bool> ensureNotDeleting(BuildContext context, WidgetRef ref) async {
  if (ref.read(deletionProcessingProvider) == DeletionProcessingState.idle) {
    return true;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => const DeletionRunningDialog(),
  );
  return false;
}

/// Shows [summary]'s takeout, then closes the dialogs over the screen. A
/// channel's page or its deletion script may not be in the new takeout, so
/// those go back to the channel list.
Future<void> switchToTakeout(
  BuildContext context,
  WidgetRef ref,
  TakeoutSummary summary, {
  String? channelId,
}) async {
  if (!await ensureNotDeleting(context, ref)) return;
  if (!context.mounted) return;
  final router = StackRouterScope.of(context)?.controller;
  await ref
      .read(takeoutSelectionProvider.notifier)
      .select(summary.id, channelId: channelId);
  if (!context.mounted) return;
  leaveChannelScreens(context, router);
}

/// Closes open dialogs, and leaves screens tied to the previous channel.
void leaveChannelScreens(BuildContext context, StackRouter? router) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).popUntil((route) => route is! PopupRoute);
  if (router == null) return;
  if (router.isRouteActive(ChannelDetailRoute.name) ||
      router.isRouteActive(ScriptDeletionRoute.name)) {
    router.replaceAll([const HomeRoute(), const ChannelListRoute()]);
  }
}

/// Switching or signing out has to wait while the YouTube API deletes.
class DeletionRunningDialog extends ConsumerWidget {
  const DeletionRunningDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pausing =
        ref.watch(deletionProcessingProvider) ==
        DeletionProcessingState.pausing;
    return AlertDialog(
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      title: const Text('Deleting in progress'),
      content: const Text(
        'Items are being deleted through the YouTube API. Pause it first, '
        'then try again once it stops.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: pausing
              ? null
              : () {
                  ref.read(deletionQueueProvider.notifier).pauseProcessing();
                  Navigator.pop(context);
                },
          child: Text(pausing ? 'Pausing…' : 'Pause deletion'),
        ),
      ],
    );
  }
}
