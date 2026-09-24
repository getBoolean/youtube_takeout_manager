import 'package:auto_route/auto_route.dart';
import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/features/comments/service/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/model/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/model/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_actions.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_queue_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/select_all_toggle_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import 'package:youtube_takeout_manager/src/features/deletion/service/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/debounced_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_preview.dart';
import 'package:youtube_takeout_manager/src/features/emoji/service/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/service/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/service/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/service/video_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../../model/search_result_item.dart';
import '../../service/channel_providers.dart';
import '../../service/cross_channel_search_providers.dart';
import 'channel_tile.dart';

@RoutePage()
class ChannelListScreen extends ConsumerStatefulWidget {
  const ChannelListScreen({super.key});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  void Function()? _cancelChannelsSub;
  void Function()? _cancelProgressSub;
  void Function()? _cancelLiveChatsSub;
  final ValueNotifier<bool> _selectionMode = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen for new channels and queue their thumbnails
      final channelsSub = ref.listenManual(channelsProvider, (prev, next) {
        final ids = next.map((c) => c.channelId).toSet();
        ref.read(channelThumbnailsProvider.notifier).queueChannelIds(ids);
      });
      _cancelChannelsSub = channelsSub.close;

      // Flush remaining thumbnail queue when video fetch completes
      final progressSub = ref.listenManual(videoFetchProgressProvider, (
        prev,
        next,
      ) {
        if (prev != null && prev.isFetching && !next.isFetching) {
          ref.read(channelThumbnailsProvider.notifier).flushQueue();
        }
      });
      _cancelProgressSub = progressSub.close;

      // Look up names for custom emojis once live chats are loaded
      final liveChatsSub = ref.listenManual(allLiveChatsProvider, (_, next) {
        if (next.isNotEmpty) {
          ref.read(emojiNamesProvider.notifier).resolveMissing();
        }
      }, fireImmediately: true);
      _cancelLiveChatsSub = liveChatsSub.close;
    });
  }

  void _exitSelectionMode() {
    _selectionMode.value = false;
    ref.read(deletionSetProvider.notifier).clear();
  }

  void _handleGlobalDelete(String value) {
    final allComments = ref.read(allCommentsProvider);
    final allLiveChats = ref.read(allLiveChatsProvider);

    final isComments = value == 'delete_all_comments';
    final count = isComments ? allComments.length : allLiveChats.length;
    final label = isComments ? 'comments' : 'live chats';

    if (count == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No $label to delete')));
      return;
    }

    deleteFromYouTube(
      context,
      ref,
      isComments
          ? DeletionTargets(
              commentSnippets: {
                for (final c in allComments) c.commentId: c.displayText,
              },
            )
          : DeletionTargets(
              liveChatSnippets: {
                for (final c in allLiveChats) c.liveChatId: c.displayText,
              },
            ),
    );
  }

  void _handleDeleteSearchResults() {
    final deletable = ref.read(crossChannelDeletableItemsProvider);
    if (deletable.isEmpty) return;

    deleteFromYouTube(context, ref, _deletionTargetsOf(deletable));
  }

  @override
  void dispose() {
    _cancelChannelsSub?.call();
    _cancelProgressSub?.call();
    _cancelLiveChatsSub?.call();
    _selectionMode.dispose();
    super.dispose();
  }

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    final skeletonColor = theme.colorScheme.surfaceContainerHighest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56 + 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const SearchBar(
              hintText: 'Search channels and comments...',
              leading: Icon(Icons.search),
              enabled: false,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        itemExtent: 56,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: skeletonColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final takeoutAsync = ref.watch(takeoutProvider);

    final filteredChannels = ref.watch(filteredChannelsProvider);
    final searchItems = ref.watch(crossChannelSearchItemsProvider);
    final progress = ref.watch(videoFetchProgressProvider);
    final query = ref.watch(channelSearchQueryProvider);
    final videoMetadata = ref.watch(videoMetadataProvider);
    final hasData = takeoutAsync.hasValue && takeoutAsync.value != null;
    final isLoading =
        !hasData ||
        (filteredChannels.isEmpty &&
            query.isEmpty &&
            (progress.isFetching || videoMetadata.isLoading));

    // When the query clears, selection mode makes no sense (results vanish).
    ref.listen(channelSearchQueryProvider, (_, next) {
      if (next.isEmpty && _selectionMode.value) {
        _exitSelectionMode();
      }
    });

    if (isLoading) {
      return _buildLoadingSkeleton();
    }

    final hasResults = filteredChannels.isNotEmpty || searchItems.isNotEmpty;

    final hasSelection = ref.watch(
      deletionSetProvider.select((s) => s.isNotEmpty),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: _selectionMode,
      builder: (context, inSelection, _) {
        return Scaffold(
          appBar: _buildAppBar(
            context: context,
            query: query,
            searchItems: searchItems,
            inSelection: inSelection,
          ),
          body: !hasResults
              ? EmptyState(
                  icon: progress.isFetching
                      ? Icons.hourglass_top
                      : Icons.search_off,
                  message: progress.isFetching
                      ? 'Loading channels...'
                      : query.isNotEmpty
                      ? 'No results found'
                      : 'No channels found',
                )
              : _buildResultsList(
                  channels: filteredChannels,
                  items: searchItems,
                  query: query,
                  inSelection: inSelection,
                ),
          bottomNavigationBar: AnimatedBottomBar(
            visible: inSelection && hasSelection,
            child: _CrossChannelDeletionBar(onExit: _exitSelectionMode),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar({
    required BuildContext context,
    required String query,
    required List<SearchResultItem> searchItems,
    required bool inSelection,
  }) {
    final progress = ref.watch(videoFetchProgressProvider);
    final hasQuery = query.isNotEmpty;
    final deletableCount = hasQuery
        ? ref.watch(crossChannelDeletableItemsProvider).length
        : 0;

    final Widget? leading;
    final Widget title;
    final List<Widget> actions;

    if (inSelection) {
      final visibleIds = {for (final item in searchItems) item.id};
      final selectedCount = ref
          .watch(deletionSetProvider)
          .intersection(visibleIds)
          .length;
      final deletableIds = {
        for (final item in ref.watch(crossChannelDeletableItemsProvider))
          item.id,
      };
      leading = IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      );
      title = Text('$selectedCount selected');
      actions = [SelectAllToggleButton(selectableIds: deletableIds)];
    } else {
      leading = context.router.canPop()
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.router.replaceAll([const HomeRoute()]),
            );
      title = const Text('Channels');
      actions = [
        if (hasQuery && deletableCount > 0)
          IconButton(
            icon: const Icon(Icons.playlist_remove),
            tooltip: 'Delete search results ($deletableCount)',
            onPressed: _handleDeleteSearchResults,
          ),
        const DeletionQueueButton(),
        PopupMenuButton<String>(
          onSelected: (value) => _handleGlobalDelete(value),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'delete_all_comments',
              child: Text('Delete All Comments from YouTube'),
            ),
            PopupMenuItem(
              value: 'delete_all_chats',
              child: Text('Delete All Live Chats from YouTube'),
            ),
          ],
        ),
      ];
    }

    return AppBar(
      leading: leading,
      title: title,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(
          56 + 4, // search bar + progress indicator
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Cue.onToggle(
              toggled: progress.isFetching && progress.total > 0,
              motion: premiumSpring(context),
              reverseMotion: premiumSpring(context),
              acts: const [ClipAct.height(), OpacityAct.fadeIn()],
              child: LinearProgressIndicator(
                value: progress.total > 0
                    ? progress.fetched / progress.total
                    : 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DebouncedSearchBar(
                hintText: 'Search channels and comments...',
                emojis: EmojiSearchConfig(
                  groups: ref.watch(allChannelEmojiGroupsProvider),
                  groupByChannel: true,
                ),
                onQueryChanged: (value) =>
                    ref.read(channelSearchQueryProvider.notifier).update(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList({
    required List<dynamic> channels,
    required List<SearchResultItem> items,
    required String query,
    required bool inSelection,
  }) {
    // Empty query → plain channel list (preserves pre-existing scroll behavior).
    if (items.isEmpty && query.isEmpty) {
      return ListView.builder(
        itemExtent: 56,
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return ChannelTile(
            key: ValueKey(channel.channelId),
            channel: channel,
            highlightQuery: query,
            onTap: inSelection
                ? () {}
                : () => context.router.push(
                    ChannelDetailRoute(channelId: channel.channelId),
                  ),
          );
        },
      );
    }

    // Query active → channels first (prioritized), then cross-channel items.
    return CustomScrollView(
      slivers: [
        if (channels.isNotEmpty)
          SliverFixedExtentList.builder(
            itemExtent: 56,
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ChannelTile(
                key: ValueKey(channel.channelId),
                channel: channel,
                highlightQuery: query,
                onTap: inSelection
                    ? () {}
                    : () => context.router.push(
                        ChannelDetailRoute(channelId: channel.channelId),
                      ),
              );
            },
          ),
        if (items.isNotEmpty)
          const SliverToBoxAdapter(
            child: _SectionHeader(label: 'Comments & live chats'),
          ),
        if (items.isNotEmpty)
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => _CrossChannelResultTile(
              key: ValueKey('${items[index].kind}:${items[index].id}'),
              item: items[index],
              query: query,
              selectionMode: _selectionMode,
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CrossChannelResultTile extends ConsumerWidget {
  final SearchResultItem item;
  final String query;
  final ValueNotifier<bool> selectionMode;

  const _CrossChannelResultTile({
    super.key,
    required this.item,
    required this.query,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channel = ref.watch(channelByIdProvider(item.channelId));
    final isQueued = _isQueued(ref);
    final isFailed = _isFailed(ref);
    final ineligible = isQueued || isFailed;
    final isSelected = ref.watch(
      deletionSetProvider.select((s) => s.contains(item.id)),
    );
    final spans = buildCommentSpans(
      item.rawText,
      emojiSize: 16,
      emojiBuilder: EmojiPreview.builder,
    );

    final isComment = item.kind == QueueItemKind.comment;
    final channelName = channel?.channelTitle ?? item.channelId;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    void toggleSelection() {
      ref.read(deletionSetProvider.notifier).toggle(item.id);
    }

    void navigateToDetail() {
      // Clear any stale per-channel search queries so the target item
      // isn't filtered out on the detail screen.
      ref.read(commentSearchQueryProvider.notifier).update('');
      ref.read(liveChatSearchQueryProvider.notifier).update('');
      context.router.push(
        ChannelDetailRoute(
          channelId: item.channelId,
          targetKind: item.kind == QueueItemKind.comment
              ? 'comment'
              : 'liveChat',
          targetId: item.id,
        ),
      );
    }

    return AnimatedOpacity(
      opacity: (isQueued || isFailed) ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Cue.onChange(
            value: selectionMode.value,
            motion: premiumSpring(context),
            acts: const [OpacityAct.fadeIn()],
            child: Center(
              child: selectionMode.value
                  ? Checkbox(
                      key: const ValueKey('checkbox'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: isSelected,
                      onChanged: ineligible ? null : (_) => toggleSelection(),
                    )
                  : Icon(
                      key: const ValueKey('icon'),
                      isComment
                          ? Icons.comment_outlined
                          : Icons.chat_bubble_outline,
                      color: isComment
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
            ),
          ),
        ),
        title: HighlightedText.rich(
          spans,
          query: query,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Row(
          children: [
            Text('on ', style: subtitleStyle),
            if (channel?.thumbnailUrl != null) ...[
              ClipOval(
                child: Image.network(
                  channel!.thumbnailUrl!,
                  width: 14,
                  height: 14,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                '$channelName · ${formatDateTime(item.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
            ),
          ],
        ),
        trailing: isQueued
            ? Icon(
                Icons.hourglass_top,
                size: 18,
                color: theme.colorScheme.tertiary,
              )
            : isFailed
            ? Icon(
                Icons.error_outline,
                size: 18,
                color: theme.colorScheme.error,
              )
            : const Icon(Icons.chevron_right),
        selected: isSelected,
        onTap: selectionMode.value
            ? (ineligible ? () {} : toggleSelection)
            : navigateToDetail,
        onLongPress: ineligible
            ? null
            : () {
                selectionMode.value = true;
                toggleSelection();
              },
      ),
    );
  }

  bool _isQueued(WidgetRef ref) {
    return item.kind == QueueItemKind.comment
        ? ref.watch(queuedCommentIdsProvider).contains(item.id)
        : ref.watch(queuedLiveChatIdsProvider).contains(item.id);
  }

  bool _isFailed(WidgetRef ref) {
    return item.kind == QueueItemKind.comment
        ? ref.watch(failedCommentIdsProvider).contains(item.id)
        : ref.watch(failedLiveChatIdsProvider).contains(item.id);
  }
}

class _CrossChannelDeletionBar extends ConsumerWidget {
  final VoidCallback onExit;

  const _CrossChannelDeletionBar({required this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(crossChannelSearchItemsProvider);
    final selectedIds = ref.watch(deletionSetProvider);

    // Keep rendering even when empty so AnimatedBottomBar has stable content to
    // fade/slide out during the exit animation. The parent gates visibility via
    // `inSelection && hasSelection`, so "0 items" only appears mid-animation.
    return SelectionActionBar(
      selection: _deletionTargetsOf(
        items.where((item) => selectedIds.contains(item.id)),
      ),
      onExitSelection: onExit,
    );
  }
}

DeletionTargets _deletionTargetsOf(Iterable<SearchResultItem> items) {
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
