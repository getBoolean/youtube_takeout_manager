import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import 'package:youtube_takeout_manager/src/common_widgets/label_badge.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import '../application/saved_takeouts.dart';
import '../application/takeout_selection_notifier.dart';
import '../domain/takeout_channel.dart';
import 'takeout_switcher.dart';

Future<void> showSwitchTakeoutDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const SwitchTakeoutDialog(),
);

/// Every saved takeout, to switch to or remove, and sign-ins kept for
/// channels no saved takeout has.
class SwitchTakeoutDialog extends ConsumerWidget {
  const SwitchTakeoutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final takeouts = ref.watch(savedTakeoutsProvider);
    final viewingId = ref.watch(
      takeoutSelectionProvider.select((s) => s.value?.takeoutId),
    );
    final signIns = ref.watch(savedSignInsProvider).value ?? const {};
    final inTakeouts = {
      for (final t in takeouts.value ?? const <TakeoutSummary>[])
        ...t.channelIds,
    };
    final otherSignIns = [
      for (final profile in signIns.values)
        if (!inTakeouts.contains(profile.channelId)) profile,
    ];

    return Dialog(
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 8, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Saved takeouts',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const CloseButton(),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...switch (takeouts) {
                      AsyncData(:final value) when value.isEmpty => [
                        const Text('No takeouts saved.'),
                      ],
                      AsyncData(:final value) => [
                        for (final summary in value)
                          _TakeoutCard(
                            summary: summary,
                            viewing: summary.id == viewingId,
                          ),
                      ],
                      AsyncError(:final error) => [
                        Text("Couldn't list saved takeouts: $error"),
                      ],
                      _ => [const Center(child: CircularProgressIndicator())],
                    },
                    if (otherSignIns.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Other saved sign-ins',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        "For channels in none of these takeouts. They're used "
                        'if you import one of their takeouts.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      for (final profile in otherSignIns)
                        _OtherSignIn(profile: profile),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TakeoutCard extends ConsumerWidget {
  final TakeoutSummary summary;
  final bool viewing;

  const _TakeoutCard({required this.summary, required this.viewing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final main = summary.main;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChannelIdentity(
                  channelId: main.channelId,
                  title: main.title,
                  thumbnailUrl: main.thumbnailUrl,
                ),
                if (viewing) const LabelBadge('Viewing'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              describeTakeout(summary),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (!viewing)
                  FilledButton.tonal(
                    onPressed: () => switchToTakeout(context, ref, summary),
                    child: const Text('Switch', textAlign: TextAlign.center),
                  ),
                TextButton(
                  onPressed: () => _remove(context, ref),
                  child: const Text('Remove', textAlign: TextAlign.center),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    if (viewing && !await ensureNotDeleting(context, ref)) return;
    final saved = ref.read(savedTakeoutsProvider.notifier);
    final removal = await saved.planRemoval(summary.id);
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RemoveTakeoutDialog(removal: removal),
    );
    if (confirmed != true || !context.mounted) return;
    final router = StackRouterScope.of(context)?.controller;
    await saved.removeTakeout(removal);
    if (viewing && context.mounted) leaveChannelScreens(context, router);
  }
}

class _OtherSignIn extends ConsumerWidget {
  final SignInProfile profile;

  const _OtherSignIn({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          ChannelIdentity(
            channelId: profile.channelId,
            title: profile.channelTitle,
          ),
          TextButton(
            onPressed: () => ref
                .read(savedSignInsProvider.notifier)
                .remove(profile.channelId, revoke: true),
            child: const Text('Remove sign-in', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// Confirms removing a saved takeout, saying everything that goes with it.
class RemoveTakeoutDialog extends StatelessWidget {
  final TakeoutRemoval removal;

  const RemoveTakeoutDialog({super.key, required this.removal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = removal.summary;
    final name = summary.main.title ?? summary.main.channelId;
    return AlertDialog(
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      title: Text('Remove $name?'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final channel in summary.channels) ...[
              ChannelIdentity(
                channelId: channel.channelId,
                title: channel.title,
                thumbnailUrl: channel.thumbnailUrl,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Text(
              [
                'Its data is removed from this device.',
                if (removal.queuedCount > 0)
                  Intl.plural(
                    removal.queuedCount,
                    one: 'Its 1 queued deletion is removed too.',
                    other:
                        'Its ${removal.queuedCount} queued deletions are '
                        'removed too.',
                  ),
                if (removal.signInIds.isNotEmpty)
                  'Its channels are signed out.',
                'Nothing is deleted from YouTube, and importing the takeout '
                    'again brings it back.',
              ].join(' '),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}

/// A saved takeout's channel count, item counts and export date, as far as
/// they're known, e.g. "2 channels · 1,234 comments · 56 live chats ·
/// exported Apr 12, 2026".
String describeTakeout(TakeoutSummary summary) {
  final number = NumberFormat.decimalPattern();
  final channels = summary.channels.length;
  final comments = summary.channels.fold(0, (n, c) => n + c.commentCount);
  final liveChats = summary.channels.fold(0, (n, c) => n + c.liveChatCount);
  return [
    if (channels > 1) '$channels channels',
    if (summary.countsKnown) ...[
      Intl.plural(
        comments,
        one: '1 comment',
        other: '${number.format(comments)} comments',
      ),
      Intl.plural(
        liveChats,
        one: '1 live chat',
        other: '${number.format(liveChats)} live chats',
      ),
    ],
    if (summary.latestExportAt case final exported?)
      'exported ${DateFormat.yMMMd().format(exported.toLocal())}',
  ].join(' · ');
}
