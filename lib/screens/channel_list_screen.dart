import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/channel_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/deletion_queue_provider.dart';
import '../providers/live_chat_providers.dart';
import '../providers/video_providers.dart';
import '../router/app_router.dart';
import '../widgets/channel_tile.dart';
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete All ${isComments ? 'Comments' : 'Live Chats'}'),
        content: Text(
            'Queue all $count $label for permanent deletion from YouTube?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final notifier = ref.read(deletionQueueProvider.notifier);
              if (isComments) {
                final snippets = <String, String?>{
                  for (final c in allComments) c.commentId: c.displayText,
                };
                notifier.enqueueComments(
                  allComments.map((c) => c.commentId).toSet(),
                  snippets: snippets,
                );
              } else {
                final snippets = <String, String?>{
                  for (final c in allLiveChats) c.liveChatId: c.displayText,
                };
                notifier.enqueueLiveChats(
                  allLiveChats.map((c) => c.liveChatId).toSet(),
                  snippets: snippets,
                );
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelChannelsSub?.call();
    _cancelProgressSub?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredChannelsProvider);
    final progress = ref.watch(videoFetchProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Deletion Queue',
            onPressed: () =>
                context.router.push(const DeletionQueueRoute()),
          ),
          if (progress.isFetching)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.total > 0
                      ? progress.fetched / progress.total
                      : null,
                ),
              ),
            )
          else
            IconButton(
              onPressed: () =>
                  ref.read(videoMetadataProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh metadata',
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
