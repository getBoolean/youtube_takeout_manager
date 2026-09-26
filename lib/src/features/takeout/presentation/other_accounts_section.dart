import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import '../application/saved_takeouts.dart';
import '../domain/takeout_channel.dart';
import 'channel_picker_dialog.dart';

/// A saved takeout other than the one viewed, with the sign-in naming its
/// Google account, if any.
class OtherAccount {
  final TakeoutSummary summary;
  final SignInProfile? profile;

  const OtherAccount({required this.summary, this.profile});
}

/// The other saved Google accounts, shown in the viewed account's tile:
/// open one to view any of its channels, remove it after confirming in
/// place, or add another. Then sign-ins for channels no takeout has.
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
  final ValueChanged<TakeoutRemoval> onRemove;

  final List<SignInProfile> otherSignIns;
  final ValueChanged<String> onRemoveSignIn;

  /// Adds another account's takeout.
  final Widget addAccount;

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
    required this.addAccount,
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
          const SizedBox(height: 8),
        ],
        addAccount,
        if (otherSignIns.isNotEmpty) ...[
          const SizedBox(height: 16),
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
                label: Text(
                  'Remove ${_nameOf(viewed)} from this device',
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

String _nameOf(TakeoutSummary summary) =>
    summary.main.title ?? summary.main.channelId;

/// Shows [builder]'s button until it's pressed, then asks in place whether
/// to remove the takeout, saying what goes with it.
class _Removable extends StatefulWidget {
  final Future<TakeoutRemoval> Function() planRemoval;
  final ValueChanged<TakeoutRemoval> onRemove;
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
  var _planning = false;

  Future<void> _plan() async {
    setState(() => _planning = true);
    try {
      final removal = await widget.planRemoval();
      if (mounted) setState(() => _removal = removal);
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final removal = _removal;
    if (removal == null) return widget.builder(_planning ? null : _plan);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RemoveTakeoutConfirmation(
        removal: removal,
        onCancel: () => setState(() => _removal = null),
        onConfirm: () {
          setState(() => _removal = null);
          widget.onRemove(removal);
        },
      ),
    );
  }
}

class _OtherAccountRow extends StatefulWidget {
  final OtherAccount account;
  final bool deletionRunning;
  final ValueChanged<String> onView;
  final Future<TakeoutRemoval> Function() planRemoval;
  final ValueChanged<TakeoutRemoval> onRemove;

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
    final name = profile?.displayName ?? profile?.email ?? _nameOf(summary);
    final email = profile?.displayName != null ? profile?.email : null;
    final details = describeTakeout(summary);
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final showAvatar = MediaQuery.sizeOf(context).width >= 200;

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
              child: const Text('Remove', textAlign: TextAlign.center),
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
    final name = channel.title ?? channel.channelId;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            if (MediaQuery.sizeOf(context).width >= 200) ...[
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
      title: 'Remove ${_nameOf(removal.summary)}?',
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
          child: const Text('Remove', textAlign: TextAlign.center),
        ),
      ],
      children: [
        Text(
          [
            'Its data is removed from this device.',
            if (removal.queuedCount > 0)
              Intl.plural(
                removal.queuedCount,
                one: 'Its 1 queued deletion is removed too.',
                other:
                    'Its ${removal.queuedCount} queued deletions are removed '
                    'too.',
              ),
            if (removal.signInIds.isNotEmpty) 'Its channels are signed out.',
            'Nothing is deleted from YouTube, and importing the takeout again '
                'brings it back.',
          ].join(' '),
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
