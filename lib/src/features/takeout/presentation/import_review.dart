import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../domain/takeout_import_plan.dart';
import 'import_items_dialog.dart';

/// What importing [plan] will change, for looking over before it's saved.
/// Each count of new or deleted items opens a list of them.
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

    /// A count of [items], opening a list of them when there are any.
    Widget counted(
      List<Interaction> items,
      IconData icon,
      String text, {
      required String key,
    }) => _Line(
      key: ValueKey(key),
      icon,
      text,
      onOpen: items.isEmpty
          ? null
          : () => showImportItemsDialog(context, title: text, items: items),
    );

    // Merged data is sorted newest first.
    List<Interaction> commentsIn(Set<String> ids) => [
      for (final c in data.comments)
        if (ids.contains(c.commentId)) c,
    ];
    List<Interaction> liveChatsIn(Set<String> ids) => [
      for (final l in data.liveChats)
        if (ids.contains(l.liveChatId)) l,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan.accountAssumed) ...[
          // Nothing in it says whose it is: name where it goes, to confirm.
          Column(
            key: const ValueKey('import-account-assumed'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nothing in this takeout says which account it's from: it has "
                'no comments, live chats or channel list. It will be added '
                'to:',
                style: theme.textTheme.bodyMedium,
              ),
              if (plan.channels.firstOrNull case final main?)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ChannelIdentity(
                    channelId: main.channelId,
                    title: main.title,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ] else if (plan.channels.length > 1 ||
            (!merge && plan.channels.isNotEmpty)) ...[
          Text(
            'Channels in this takeout',
            key: const ValueKey('import-review-channels'),
            style: theme.textTheme.titleSmall,
          ),
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
        // Nothing in it names a channel, so it has no comments or live chats.
        if (!plan.accountAssumed && merge) ...[
          counted(
            commentsIn(plan.newCommentIds),
            Icons.comment_outlined,
            formatCount(plan.newCommentCount, 'new comment'),
            key: 'import-new-comments',
          ),
          counted(
            liveChatsIn(plan.newLiveChatIds),
            Icons.chat_bubble_outline,
            formatCount(plan.newLiveChatCount, 'new live chat'),
            key: 'import-new-live-chats',
          ),
        ] else if (!plan.accountAssumed) ...[
          _Line(
            Icons.comment_outlined,
            formatCount(data.comments.length, 'comment'),
          ),
          _Line(
            Icons.chat_bubble_outline,
            formatCount(data.liveChats.length, 'live chat'),
          ),
        ],
        if (plan.history.merged case final history?) ...[
          _Line(
            key: const ValueKey('import-watches'),
            Icons.history,
            merge
                ? formatCount(plan.history.newWatchCount, 'new watched video')
                : formatCount(history.watches.length, 'watched video'),
          ),
          _Line(
            key: const ValueKey('import-searches'),
            Icons.search,
            merge
                ? formatCount(
                    plan.history.newSearchCount,
                    'new search',
                    plural: 'new searches',
                  )
                : formatCount(
                    history.searches.length,
                    'search',
                    plural: 'searches',
                  ),
          ),
        ],
        if (plan.newlyDeletedCommentCount > 0 ||
            plan.newlyDeletedLiveChatCount > 0) ...[
          const SizedBox(height: 16),
          Text('No longer on YouTube', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (plan.newlyDeletedCommentCount > 0)
            counted(
              commentsIn(plan.newlyDeletedCommentIds),
              Icons.delete_outline,
              '${formatCount(plan.newlyDeletedCommentCount, 'comment')} will '
              'be marked deleted',
              key: 'import-marks-comments-deleted',
            ),
          if (plan.newlyDeletedLiveChatCount > 0)
            counted(
              liveChatsIn(plan.newlyDeletedLiveChatIds),
              Icons.delete_outline,
              '${formatCount(plan.newlyDeletedLiveChatCount, 'live chat')} '
              'will be marked deleted',
              key: 'import-marks-live-chats-deleted',
            ),
        ],
        if (plan.history.newlyRemovedWatchCount > 0 ||
            plan.history.newlyRemovedSearchCount > 0) ...[
          const SizedBox(height: 16),
          Text(
            'No longer in your YouTube history',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          if (plan.history.newlyRemovedWatchCount > 0)
            _Line(
              key: const ValueKey('import-watches-removed'),
              Icons.history_toggle_off,
              '${formatCount(plan.history.newlyRemovedWatchCount, 'watched video')} '
              'will be kept, marked removed',
            ),
          if (plan.history.newlyRemovedSearchCount > 0)
            _Line(
              key: const ValueKey('import-searches-removed'),
              Icons.history_toggle_off,
              '${formatCount(plan.history.newlyRemovedSearchCount, 'search', plural: 'searches')} '
              'will be kept, marked removed',
            ),
        ],
        for (final (:key, :warning) in _warnings()) ...[
          const SizedBox(height: 12),
          _Notice(
            key: ValueKey(key),
            icon: Icons.info_outline,
            color: theme.colorScheme.tertiary,
            text: warning,
          ),
        ],
      ],
    );
  }

  /// Each warning, keyed by the kind it's about.
  List<({String key, String warning})> _warnings() {
    String? warning(
      DeletionCheckSkipReason? reason,
      int skippedRows,
      String item,
    ) {
      final items = '${item}s';
      final unreadRows = skippedRows > 0
          ? "${formatCount(skippedRows, '$item row')} couldn't be read"
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
      if (warning(plan.commentCheckSkipped, data.skippedCommentRows, 'comment')
          case final text?)
        (key: 'import-warning-comments', warning: text),
      if (warning(
            plan.liveChatCheckSkipped,
            data.skippedLiveChatRows,
            'live chat',
          )
          case final text?)
        (key: 'import-warning-live-chats', warning: text),
      if (_historyWarning() case final text?)
        (key: 'import-warning-history', warning: text),
    ];
  }

  String? _historyWarning() {
    final history = plan.history;
    final notMarked = history.removalCheckSkipped
        ? ", so history missing from this takeout wasn't marked removed"
        : '';
    if (history.unreadableFiles > 0) {
      return "This takeout's history couldn't be read, perhaps because it's "
          'in another language$notMarked. Export it again with history as '
          'JSON to add it.';
    }
    if (history.skippedRows > 0) {
      return '${formatCount(history.skippedRows, 'history entry', plural: 'history entries')} '
          "couldn't be read$notMarked.";
    }
    return null;
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  /// Lists the items counted; null when there are none.
  final VoidCallback? onOpen;

  const _Line(this.icon, this.text, {super.key, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          if (onOpen != null) const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
    if (onOpen == null) return row;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(4),
        child: row,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

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
