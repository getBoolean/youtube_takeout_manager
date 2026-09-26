import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import '../domain/takeout_import_plan.dart';

/// What importing [plan] will change, for looking over before it's saved.
class ImportReview extends StatelessWidget {
  final TakeoutImportPlan plan;

  /// Whether the takeout is merged into its account's saved data, rather
  /// than saved as a new account, whose channels are always named.
  final bool merge;

  const ImportReview({super.key, required this.plan, required this.merge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = plan.mergedData;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan.channels.length > 1 ||
            (!merge && plan.channels.isNotEmpty)) ...[
          Text('Channels in this takeout', style: theme.textTheme.titleSmall),
          for (final channel in plan.channels)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ChannelIdentity(
                channelId: channel.channelId,
                title: channel.title,
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (merge) ...[
          _Line(
            Icons.comment_outlined,
            _count(plan.newCommentCount, 'new comment'),
          ),
          _Line(
            Icons.chat_bubble_outline,
            _count(plan.newLiveChatCount, 'new live chat'),
          ),
        ] else ...[
          _Line(
            Icons.comment_outlined,
            _count(data.comments.length, 'comment'),
          ),
          _Line(
            Icons.chat_bubble_outline,
            _count(data.liveChats.length, 'live chat'),
          ),
        ],
        if (plan.newlyDeletedCommentCount > 0 ||
            plan.newlyDeletedLiveChatCount > 0) ...[
          const SizedBox(height: 16),
          Text('No longer on YouTube', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (plan.newlyDeletedCommentCount > 0)
            _Line(
              Icons.delete_outline,
              '${_count(plan.newlyDeletedCommentCount, 'comment')} will '
              'be marked deleted',
            ),
          if (plan.newlyDeletedLiveChatCount > 0)
            _Line(
              Icons.delete_outline,
              '${_count(plan.newlyDeletedLiveChatCount, 'live chat')} '
              'will be marked deleted',
            ),
        ],
        for (final warning in _warnings()) ...[
          const SizedBox(height: 12),
          _Notice(
            icon: Icons.info_outline,
            color: theme.colorScheme.tertiary,
            text: warning,
          ),
        ],
      ],
    );
  }

  List<String> _warnings() {
    String? warning(
      DeletionCheckSkipReason? reason,
      int skippedRows,
      String item,
    ) {
      final items = '${item}s';
      final unreadRows = skippedRows > 0
          ? "${_count(skippedRows, '$item row')} couldn't be read"
          : null;
      return switch (reason) {
        DeletionCheckSkipReason.incompleteFiles =>
          'Some $item files may be missing from this takeout, so $items '
              "missing from it weren't marked deleted. If the export was "
              'split into several zips, pick every part.',
        DeletionCheckSkipReason.savedDataUnverified =>
          'Your saved $items are newer than this takeout but may be '
              "incomplete, so $items weren't marked deleted. Add a newer, "
              'complete takeout to check them.',
        DeletionCheckSkipReason.unparsedRows =>
          '${unreadRows ?? "Some rows couldn't be read"}, so $items missing '
              "from this takeout weren't marked deleted.",
        null => unreadRows != null ? '$unreadRows.' : null,
      };
    }

    final data = plan.mergedData;
    return [
      ?warning(plan.commentCheckSkipped, data.skippedCommentRows, 'comment'),
      ?warning(
        plan.liveChatCheckSkipped,
        data.skippedLiveChatRows,
        'live chat',
      ),
    ];
  }
}

String _count(int n, String noun) => '$n ${n == 1 ? noun : '${noun}s'}';

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Line(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
