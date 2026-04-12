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
  bool _fetching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    setState(() => _fetching = true);
    try {
      await ref.read(videoMetadataProvider.notifier).fetchMetadata();
      final channelIds =
          ref.read(channelsProvider).map((c) => c.channelId).toSet();
      await ref
          .read(channelThumbnailsProvider.notifier)
          .fetchThumbnails(channelIds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(content: Text('Failed to fetch metadata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredChannelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        actions: [
          if (_fetching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _fetchMetadata,
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: 'Fetch video info',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: 'Search channels...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  ref.read(channelSearchQueryProvider.notifier).update(value);
                });
              },
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? const EmptyState(
              icon: Icons.search_off,
              message: 'No channels found',
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
