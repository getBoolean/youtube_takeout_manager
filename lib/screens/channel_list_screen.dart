import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/queue_item_kind.dart';
import '../models/search_result_item.dart';
import '../providers/auth_providers.dart';
import '../providers/channel_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/cross_channel_search_providers.dart';
import '../providers/deleted_ids_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/live_chat_providers.dart';
import '../providers/takeout_providers.dart';
import '../providers/video_providers.dart';
import '../router/app_router.dart';
import '../utils/comment_text_parser.dart';
import '../utils/date_formatter.dart';
import '../widgets/channel_tile.dart';
import '../widgets/debounced_search_bar.dart';
import '../widgets/deletion_method_picker.dart';
import '../widgets/empty_state.dart';
import '../widgets/highlighted_text.dart';
import '../widgets/queue_snackbar.dart';

@RoutePage()
class ChannelListScreen extends ConsumerStatefulWidget {
  const ChannelListScreen({super.key});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  void Function()? _cancelChannelsSub;
  void Function()? _cancelProgressSub;

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
    });
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

    final ids = isComments
        ? allComments.map((c) => c.commentId).toSet()
        : allLiveChats.map((c) => c.liveChatId).toSet();
    showDeletionMethodPicker(
      context,
      ref: ref,
      ids: ids,
      onApiChosen: () {
        final notifier = ref.read(deletionQueueProvider.notifier);
        if (isComments) {
          final snippets = <String, String?>{
            for (final c in allComments) c.commentId: c.displayText,
          };
          notifier.enqueueComments(ids, snippets: snippets);
        } else {
          final snippets = <String, String?>{
            for (final c in allLiveChats) c.liveChatId: c.displayText,
          };
          notifier.enqueueLiveChats(ids, snippets: snippets);
        }
        showQueuedForDeletionSnackBar(
          context,
          ref,
          message: '$count $label queued for deletion',
        );
      },
    );
  }

  void _handleDeleteSearchResults() {
    final deletable = ref.read(crossChannelDeletableItemsProvider);
    if (deletable.isEmpty) return;

    final commentSnippets = <String, String?>{};
    final liveChatSnippets = <String, String?>{};
    for (final item in deletable) {
      switch (item) {
        case CommentResult(:final comment):
          commentSnippets[comment.commentId] = comment.displayText;
        case LiveChatResult(:final liveChat):
          liveChatSnippets[liveChat.liveChatId] = liveChat.displayText;
      }
    }

    final allIds = {...commentSnippets.keys, ...liveChatSnippets.keys};
    showDeletionMethodPicker(
      context,
      ref: ref,
      ids: allIds,
      onApiChosen: () {
        final notifier = ref.read(deletionQueueProvider.notifier);
        if (commentSnippets.isNotEmpty) {
          notifier.enqueueComments(
            commentSnippets.keys.toSet(),
            snippets: commentSnippets,
          );
        }
        if (liveChatSnippets.isNotEmpty) {
          notifier.enqueueLiveChats(
            liveChatSnippets.keys.toSet(),
            snippets: liveChatSnippets,
          );
        }
        showQueuedForDeletionSnackBar(
          context,
          ref,
          message: '${allIds.length} item(s) queued for deletion',
        );
      },
    );
  }

  @override
  void dispose() {
    _cancelChannelsSub?.call();
    _cancelProgressSub?.call();
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

    if (isLoading) {
      return _buildLoadingSkeleton();
    }

    final hasQuery = query.isNotEmpty;
    final deletableCount = hasQuery
        ? ref.watch(crossChannelDeletableItemsProvider).length
        : 0;
    final hasResults = filteredChannels.isNotEmpty || searchItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: context.router.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.replaceAll([const HomeRoute()]),
              ),
        title: const Text('Channels'),
        actions: [
          if (hasQuery && deletableCount > 0)
            IconButton(
              icon: const Icon(Icons.playlist_remove),
              tooltip: 'Delete search results ($deletableCount)',
              onPressed: _handleDeleteSearchResults,
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Deletion Queue',
            onPressed: () => context.router.push(const DeletionQueueRoute()),
          ),
          if (ref.watch(isAuthenticatedProvider))
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            56 + 4, // search bar + progress indicator
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress.isFetching && progress.total > 0)
                LinearProgressIndicator(
                  value: progress.fetched / progress.total,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: DebouncedSearchBar(
                  hintText: 'Search channels and comments...',
                  onQueryChanged: (value) => ref
                      .read(channelSearchQueryProvider.notifier)
                      .update(value),
                ),
              ),
            ],
          ),
        ),
      ),
      body: !hasResults
          ? EmptyState(
              icon: progress.isFetching
                  ? Icons.hourglass_top
                  : Icons.search_off,
              message: progress.isFetching
                  ? 'Loading channels...'
                  : hasQuery
                  ? 'No results found'
                  : 'No channels found',
            )
          : _buildResultsList(
              channels: filteredChannels,
              items: searchItems,
              query: query,
            ),
    );
  }

  Widget _buildResultsList({
    required List<dynamic> channels,
    required List<SearchResultItem> items,
    required String query,
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
            onTap: () => context.router.push(
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
                onTap: () => context.router.push(
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

  const _CrossChannelResultTile({
    super.key,
    required this.item,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channel = ref.watch(channelByIdProvider(item.channelId));
    final isQueued = _isQueued(ref);
    final isFailed = _isFailed(ref);
    final spans = buildCommentSpans(item.rawText, emojiSize: 16);

    final isComment = item.kind == QueueItemKind.comment;
    final channelName = channel?.channelTitle ?? item.channelId;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Opacity(
      opacity: (isQueued || isFailed) ? 0.6 : 1.0,
      child: ListTile(
        leading: Icon(
          isComment ? Icons.comment_outlined : Icons.chat_bubble_outline,
          color: isComment
              ? theme.colorScheme.primary
              : theme.colorScheme.secondary,
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
            ? Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error)
            : const Icon(Icons.chevron_right),
        onTap: () {
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
