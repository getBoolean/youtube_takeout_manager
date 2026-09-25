import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/option_card.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import '../application/deletion_queue_notifier.dart';
import '../domain/deletion_method.dart';
import '../domain/deletion_targets.dart';
import 'deletion_actions.dart';

/// Asks how to delete the queue's waiting items, then starts that method.
Future<void> deleteQueuedItems(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(deletionQueueProvider.notifier);
  final waiting = DeletionTargets.fromQueueItems(notifier.pendingItems);
  if (waiting.isEmpty) return;

  final method = await showDialog<DeletionMethod>(
    context: context,
    builder: (_) => DeletionMethodDialog(
      itemCount: waiting.count,
      possibleMembershipEventCount: waiting.possibleMembershipEventCount,
    ),
  );
  if (!context.mounted) return;

  switch (method) {
    case DeletionMethod.myActivityScript:
      openMyActivityScript(context, ref, waiting.allIds);
    case DeletionMethod.youtubeApi:
      // Runs until the queue is done, paused or out of quota.
      unawaited(notifier.processPendingViaYoutubeApi());
    case null:
      return;
  }
}

/// Picks how to delete [itemCount] items from YouTube: via My Activity, or
/// via the YouTube API when signed in.
class DeletionMethodDialog extends ConsumerWidget {
  final int itemCount;
  final int possibleMembershipEventCount;

  const DeletionMethodDialog({
    super.key,
    required this.itemCount,
    this.possibleMembershipEventCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isAuthenticatedProvider);
    final deletesLeft = ref
        .watch(quotaProvider)
        .value
        ?.affordableOperations(QuotaOperation.deleteComment.cost);

    return AlertDialog(
      // Title and buttons scroll too, and the margins shrink, so nothing
      // overflows in a tiny window.
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      title: Text(
        Intl.plural(
          itemCount,
          one: 'Delete 1 item from YouTube',
          other: 'Delete $itemCount items from YouTube',
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (possibleMembershipEventCount > 0) ...[
              _PossibleMembershipEventWarning(
                count: possibleMembershipEventCount,
              ),
              const SizedBox(height: 12),
            ],
            OptionCard(
              icon: Icons.language,
              title: 'Via My Activity',
              subtitle:
                  "No daily limit, doesn't use API quota. Runs in your "
                  'browser.',
              badge: const _RecommendedBadge(),
              onTap: () =>
                  Navigator.pop(context, DeletionMethod.myActivityScript),
            ),
            const SizedBox(height: 8),
            OptionCard(
              icon: Icons.cloud_off,
              title: 'Via YouTube API',
              subtitle: !signedIn
                  ? 'Sign in required'
                  : deletesLeft == null
                  ? 'Uses API quota'
                  : Intl.plural(
                      deletesLeft,
                      one: 'Uses API quota · ~1 delete left today',
                      other:
                          'Uses API quota · ~$deletesLeft deletes left today',
                    ),
              onTap: signedIn
                  ? () => Navigator.pop(context, DeletionMethod.youtubeApi)
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Recommended',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PossibleMembershipEventWarning extends StatelessWidget {
  final int count;

  const _PossibleMembershipEventWarning({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = Intl.plural(
      count,
      one:
          '1 item may be a membership event or already-deleted message. '
          'Deletion may fail for it.',
      other:
          '$count items may be membership events or already-deleted '
          'messages. Deletion may fail for these.',
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left out in the narrowest windows so the text still fits.
          if (MediaQuery.sizeOf(context).width >= 200) ...[
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
