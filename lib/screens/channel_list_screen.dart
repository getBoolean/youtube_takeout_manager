import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/channel_providers.dart';
import '../providers/takeout_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/live_chat_providers.dart';
import '../providers/video_providers.dart';
import '../router/app_router.dart';
import '../widgets/channel_tile.dart';
import '../widgets/deletion_method_picker.dart';
import '../widgets/empty_state.dart';

@RoutePage()
class ChannelListScreen extends ConsumerStatefulWidget {
  const ChannelListScreen({super.key});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  Timer? _debounce;
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
      final progressSub =
          ref.listenManual(videoFetchProgressProvider, (prev, next) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $label to delete')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count $label queued for deletion'),
            action: SnackBarAction(
              label: 'View Queue',
              onPressed: () =>
                  context.router.push(const DeletionQueueRoute()),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
              hintText: 'Search channels...',
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

    final filtered = ref.watch(filteredChannelsProvider);
    final progress = ref.watch(videoFetchProgressProvider);
    final query = ref.watch(channelSearchQueryProvider);
    final videoMetadata = ref.watch(videoMetadataProvider);
    final hasData = takeoutAsync.hasValue && takeoutAsync.value != null;
    final isLoading = !hasData ||
        (filtered.isEmpty && query.isEmpty &&
            (progress.isFetching || videoMetadata.isLoading));

    if (isLoading) {
      return _buildLoadingSkeleton();
    }

    return Scaffold(
      appBar: AppBar(
        leading: context.router.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.router.replaceAll([const HomeRoute()]),
              ),
        title: const Text('Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Deletion Queue',
            onPressed: () =>
                context.router.push(const DeletionQueueRoute()),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SearchBar(
                  hintText: 'Search channels...',
                  leading: const Icon(Icons.search),
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      ref
                          .read(channelSearchQueryProvider.notifier)
                          .update(value);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: filtered.isEmpty
          ? EmptyState(
              icon: progress.isFetching ? Icons.hourglass_top : Icons.search_off,
              message:
                  progress.isFetching ? 'Loading channels...' : 'No channels found',
            )
          : ListView.builder(
              itemExtent: 56,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final channel = filtered[index];
                return ChannelTile(
                  key: ValueKey(channel.channelId),
                  channel: channel,
                  onTap: () => context.router.push(
                    ChannelDetailRoute(channelId: channel.channelId),
                  ),
                );
              },
            ),
    );
  }
}
