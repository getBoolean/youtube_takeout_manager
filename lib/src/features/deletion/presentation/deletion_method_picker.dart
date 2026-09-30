import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/option_card.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/oauth_configured.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/google_cloud_setup_pages.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeouts_dialog.dart';
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

  // Later pages set up a Google Cloud client, then come back to picking.
  final method = await WoltModalSheet.show<DeletionMethod>(
    context: context,
    pageListBuilder: (_) => [
      WoltModalSheetPage(
        hasTopBarLayer: false,
        trailingNavBarWidget: const Padding(
          padding: EdgeInsetsDirectional.only(end: 8),
          child: CloseButton(),
        ),
        child: Consumer(
          builder: (context, ref, _) => DeletionMethodDialog(
            itemCount: waiting.targets.count,
            possibleMembershipEventCount: waiting.possibleMembershipEvents,
            oauthConfigured: ref.watch(oauthConfiguredProvider),
            signedIn: ref.watch(isAuthenticatedProvider),
            deletesLeft: ref
                .watch(quotaProvider)
                .value
                ?.affordableOperations(QuotaOperation.deleteCost),
            onSetUpClient: () => showGoogleCloudSetup(context),
          ),
        ),
      ),
      ...GoogleCloudSetupPages.build(),
    ],
  );
  if (!context.mounted) return;

  switch (method) {
    case DeletionMethod.myActivityScript:
      service.useMyActivityScript(waiting.targets);
      context.router.push(const ScriptDeletionRoute());
    // Signed out, it starts with signing in, in the Takeouts dialog, then
    // picks up here.
    case DeletionMethod.youtubeApi when !ref.read(isAuthenticatedProvider):
      await showTakeoutsDialog(context);
      if (context.mounted) await deleteQueuedItems(context, ref);
    case DeletionMethod.youtubeApi:
      service.startYoutubeApiDeletion(waiting.channelId);
    case null:
      return;
  }
}

/// Picks how to delete [itemCount] items from YouTube, closing its modal
/// with the method: via My Activity, or via the YouTube API when [signedIn],
/// which has [deletesLeft] today if known. Signed out, the API looks locked
/// but can still be picked, to sign in. Without a Google Cloud client, as
/// [oauthConfigured] says, picking it runs [onSetUpClient] instead.
class DeletionMethodDialog extends StatelessWidget {
  final int itemCount;
  final int possibleMembershipEventCount;
  final bool oauthConfigured;
  final bool signedIn;
  final int? deletesLeft;
  final VoidCallback? onSetUpClient;

  const DeletionMethodDialog({
    super.key,
    required this.itemCount,
    this.possibleMembershipEventCount = 0,
    this.oauthConfigured = true,
    required this.signedIn,
    this.deletesLeft,
    this.onSetUpClient,
  });

  @override
  Widget build(BuildContext context) {
    final deletesLeft = this.deletesLeft;
    final tiny = isTinyWidth(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 0, tiny ? 8 : 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              Intl.plural(
                itemCount,
                one: 'Delete 1 item from YouTube',
                other: 'Delete $itemCount items from YouTube',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          if (possibleMembershipEventCount > 0) ...[
            PossibleMembershipEventsNotice(count: possibleMembershipEventCount),
            const SizedBox(height: 12),
          ],
          OptionCard(
            icon: Icons.language,
            title: 'Via My Activity',
            subtitle:
                "No daily limit, doesn't use API quota. Runs in your "
                'browser.',
            badge: const StatusPill(label: 'Recommended', color: Colors.green),
            onTap: () =>
                Navigator.pop(context, DeletionMethod.myActivityScript),
          ),
          const SizedBox(height: 8),
          OptionCard(
            icon: Icons.cloud_off,
            title: 'Via YouTube API',
            subtitle: !signedIn
                ? oauthConfigured
                      ? 'Sign in first'
                      : 'Set up a Google Cloud client first'
                : deletesLeft == null
                ? 'Uses API quota'
                : Intl.plural(
                    deletesLeft,
                    one: 'Uses API quota · ~1 delete left today',
                    other: 'Uses API quota · ~$deletesLeft deletes left today',
                  ),
            // It can't delete yet, but picking it sets up what it needs.
            unavailable: !signedIn,
            onTap: !oauthConfigured && onSetUpClient != null
                ? onSetUpClient
                : () => Navigator.pop(context, DeletionMethod.youtubeApi),
          ),
        ],
      ),
    );
  }
}
