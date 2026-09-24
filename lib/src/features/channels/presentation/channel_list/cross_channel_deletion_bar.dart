import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import '../../application/cross_channel_search_providers.dart';
import '../../domain/search_result_item.dart';

class CrossChannelDeletionBar extends ConsumerWidget {
  final VoidCallback onExit;

  const CrossChannelDeletionBar({super.key, required this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(crossChannelSearchItemsProvider);
    final selectedIds = ref.watch(deletionSetProvider);

    // Keep rendering even when empty so AnimatedBottomBar has stable content to
    // fade/slide out during the exit animation. The parent gates visibility via
    // `inSelection && hasSelection`, so "0 items" only appears mid-animation.
    return SelectionActionBar(
      selection: deletionTargetsOf(
        items.where((item) => selectedIds.contains(item.id)),
      ),
      onExitSelection: onExit,
    );
  }
}

DeletionTargets deletionTargetsOf(Iterable<SearchResultItem> items) {
  final commentSnippets = <String, String?>{};
  final liveChatSnippets = <String, String?>{};
  for (final item in items) {
    switch (item) {
      case CommentResult(:final comment):
        commentSnippets[comment.commentId] = comment.displayText;
      case LiveChatResult(:final liveChat):
        liveChatSnippets[liveChat.liveChatId] = liveChat.displayText;
    }
  }
  return DeletionTargets(
    commentSnippets: commentSnippets,
    liveChatSnippets: liveChatSnippets,
  );
}
