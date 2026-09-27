import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/option_card.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../application/deletion_service.dart';
import '../domain/deletion_method.dart';
import 'possible_membership_events_notice.dart';
import 'status_pill.dart';

/// Asks how to delete the queue's waiting items, then starts that method.
Future<void> deleteQueuedItems(BuildContext context, WidgetRef ref) async {
  final service = ref.read(deletionServiceProvider.notifier);
  final waiting = service.waiting();
  if (waiting == null) return;

  final method = await showDialog<DeletionMethod>(
    context: context,
    builder: (_) => Consumer(
      builder: (context, ref, _) => DeletionMethodDialog(
        itemCount: waiting.targets.count,
        possibleMembershipEventCount: waiting.possibleMembershipEvents,
        signedIn: ref.watch(isAuthenticatedProvider),
        deletesLeft: ref
            .watch(quotaProvider)
            .value
            ?.affordableOperations(QuotaOperation.deleteComment.cost),
      ),
    ),
  );
  if (!context.mounted) return;

  switch (method) {
    case DeletionMethod.myActivityScript:
      service.useMyActivityScript(waiting.targets);
      context.router.push(const ScriptDeletionRoute());
    case DeletionMethod.youtubeApi:
      service.startYoutubeApiDeletion(waiting.channelId);
    case null:
      return;
  }
}

/// Picks how to delete [itemCount] items from YouTube: via My Activity, or
/// via the YouTube API when [signedIn], which has [deletesLeft] today if
/// known.
class DeletionMethodDialog extends StatelessWidget {
  final int itemCount;
  final int possibleMembershipEventCount;
  final bool signedIn;
  final int? deletesLeft;

  const DeletionMethodDialog({
    super.key,
    required this.itemCount,
    this.possibleMembershipEventCount = 0,
    required this.signedIn,
    this.deletesLeft,
  });

  @override
  Widget build(BuildContext context) {
    final deletesLeft = this.deletesLeft;
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
              PossibleMembershipEventsNotice(
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
              badge: const StatusPill(
                label: 'Recommended',
                color: Colors.green,
              ),
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
