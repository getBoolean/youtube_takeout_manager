import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/channel_providers.dart';
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
