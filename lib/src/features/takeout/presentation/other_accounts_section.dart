import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import '../domain/takeout_channel.dart';
import '../domain/takeout_removal.dart';
import 'takeout_details.dart';

/// A saved takeout other than the one viewed, with the sign-in naming its
/// Google account, if any.
class OtherAccount {
  final TakeoutSummary summary;
  final SignInProfile? profile;

  const OtherAccount({required this.summary, this.profile});
}

/// The other saved Google accounts, shown in the viewed account's tile:
/// open one to view any of its channels, or remove it after confirming in
/// place. Then sign-ins for channels no takeout has.
class OtherAccountsSection extends StatelessWidget {
  /// The viewed account, which can be removed too.
  final TakeoutSummary? viewedAccount;
  final List<OtherAccount> accounts;

  /// Whether the YouTube API is deleting, so no other channel can be viewed
  /// and the viewed account can't be removed until it stops.
  final bool deletionRunning;

  /// Views a channel of another account: (takeout ID, channel ID).
  final void Function(String takeoutId, String channelId) onView;

  /// Works out what removing a takeout removes, to confirm first.
  final Future<TakeoutRemoval> Function(String takeoutId) planRemoval;
  final Future<void> Function(TakeoutRemoval removal) onRemove;

  final List<SignInProfile> otherSignIns;
  final ValueChanged<String> onRemoveSignIn;

  const OtherAccountsSection({
    super.key,
    required this.viewedAccount,
    required this.accounts,
    required this.deletionRunning,
    required this.onView,
    required this.planRemoval,
    required this.onRemove,
    required this.otherSignIns,
    required this.onRemoveSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewed = viewedAccount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accounts.isNotEmpty) ...[
          Text('Other Google accounts', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final account in accounts)
            _OtherAccountRow(
              key: ValueKey(account.summary.id),
              account: account,
              deletionRunning: deletionRunning,
              onView: (channelId) => onView(account.summary.id, channelId),
              planRemoval: () => planRemoval(account.summary.id),
              onRemove: onRemove,
            ),
        ],
        if (otherSignIns.isNotEmpty) ...[
          if (accounts.isNotEmpty) const SizedBox(height: 16),
          Text('Other saved sign-ins', style: theme.textTheme.titleSmall),
          Text(
            "For channels in none of these takeouts. They're used if you "
            'import one of their takeouts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          for (final profile in otherSignIns)
            Padding(
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
                    onPressed: () => onRemoveSignIn(profile.channelId),
                    child: const Text(
                      'Remove sign-in',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (viewed != null) ...[
          const SizedBox(height: 8),
          _Removable(
            key: ValueKey(viewed.id),
            planRemoval: () => planRemoval(viewed.id),
            onRemove: onRemove,
            builder: (remove) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: deletionRunning ? null : remove,
                icon: isTinyWidth(context)
                    ? null
                    : const Icon(Icons.delete_outline),
                label: const Text(
                  'Remove this takeout',
                  textAlign: TextAlign.start,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shows [builder]'s button until it's pressed, then asks in place whether
/// to remove the takeout, saying what goes with it. Says in place, too, if
/// that fails.
class _Removable extends StatefulWidget {
  final Future<TakeoutRemoval> Function() planRemoval;
  final Future<void> Function(TakeoutRemoval removal) onRemove;
  final Widget Function(VoidCallback? remove) builder;

  const _Removable({
    super.key,
    required this.planRemoval,
    required this.onRemove,
    required this.builder,
  });

  @override
  State<_Removable> createState() => _RemovableState();
}

class _RemovableState extends State<_Removable> {
  TakeoutRemoval? _removal;
  Object? _error;
  var _busy = false;

  Future<void> _plan() => _run(() async {
    final removal = await widget.planRemoval();
    if (mounted) setState(() => _removal = removal);
  });

  Future<void> _remove(TakeoutRemoval removal) {
    setState(() => _removal = null);
    return _run(() => widget.onRemove(removal));
  }

  Future<void> _run(Future<void> Function() step) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await step();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final removal = _removal;
    if (removal != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RemoveTakeoutConfirmation(
          removal: removal,
          onCancel: () => setState(() => _removal = null),
          onConfirm: () => _remove(removal),
        ),
      );
    }
    final button = widget.builder(_busy ? null : _plan);
    final error = _error;
    if (error == null) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: NoticeBanner(
            key: const ValueKey('remove-takeout-error'),
            title: "Couldn't remove the takeout",
            onDismiss: () => setState(() => _error = null),
            children: [Text('$error')],
          ),
        ),
      ],
    );
  }
}

class _OtherAccountRow extends StatefulWidget {
  final OtherAccount account;
  final bool deletionRunning;
  final ValueChanged<String> onView;
  final Future<TakeoutRemoval> Function() planRemoval;
  final Future<void> Function(TakeoutRemoval removal) onRemove;

  const _OtherAccountRow({
    super.key,
    required this.account,
    required this.deletionRunning,
    required this.onView,
    required this.planRemoval,
    required this.onRemove,
  });

  @override
  State<_OtherAccountRow> createState() => _OtherAccountRowState();
}

class _OtherAccountRowState extends State<_OtherAccountRow> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.account.summary;
    final profile = widget.account.profile;
    final name =
        profile?.displayName ?? profile?.email ?? summary.main.displayName;
    final email = profile?.displayName != null ? profile?.email : null;
    final details = describeTakeout(summary);
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final showAvatar = !isTinyWidth(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (showAvatar) ...[
                  ChannelAvatar(
                    name: name,
                    thumbnailUrl:
                        profile?.photoUrl ?? summary.main.thumbnailUrl,
                    radius: 18,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.bodyLarge),
                      if (email != null) Text(email, style: secondary),
                      if (details.isNotEmpty) Text(details, style: secondary),
                    ],
                  ),
                ),
                Icon(_open ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (_open)
          Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final channel in summary.channels)
                  _ChannelChoice(
                    channel: channel,
                    onTap: widget.deletionRunning
                        ? null
                        : () => widget.onView(channel.channelId),
                  ),
              ],
            ),
          ),
        _Removable(
          planRemoval: widget.planRemoval,
          onRemove: widget.onRemove,
          builder: (remove) => Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: remove,
              child: const Text('Remove takeout', textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelChoice extends StatelessWidget {
  final TakeoutChannel channel;
  final VoidCallback? onTap;

  const _ChannelChoice({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = channel.displayName;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (!isTinyWidth(context)) ...[
              ChannelAvatar(
                name: name,
                thumbnailUrl: channel.thumbnailUrl,
                radius: 14,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.bodyMedium),
                  Text(
                    describeChannelCounts(channel),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks in place whether to remove a saved takeout, saying everything that
/// goes with it.
class RemoveTakeoutConfirmation extends StatelessWidget {
  final TakeoutRemoval removal;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const RemoveTakeoutConfirmation({
    super.key,
    required this.removal,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NoticeBanner(
      title: "Remove ${removal.summary.main.displayName}'s takeout?",
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel', textAlign: TextAlign.center),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: onConfirm,
          child: const Text('Remove takeout', textAlign: TextAlign.center),
        ),
      ],
      children: [
        Text(
          [
            "The takeout's comments and live chats are removed from this "
                'device.',
            if (removal.queuedCount > 0)
              Intl.plural(
                removal.queuedCount,
                one: 'Its 1 queued deletion is removed too.',
                other:
                    'Its ${removal.queuedCount} queued deletions are removed '
                    'too.',
              ),
            if (removal.signInIds.isNotEmpty)
              'Its channels are signed out of this app.',
            'Your Google account and YouTube stay as they are: nothing is '
                'deleted there, and importing the takeout again brings it '
                'back.',
          ].join(' '),
        ),
      ],
    );
  }
}
