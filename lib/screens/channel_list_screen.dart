import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/channel_providers.dart';
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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allChannels = ref.watch(channelsProvider);
    final filtered = _searchQuery.isEmpty
        ? allChannels
        : allChannels.where((c) {
            final title = c.channelTitle?.toLowerCase() ?? '';
            final id = c.channelId.toLowerCase();
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || id.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: 'Search channels...',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _searchQuery = value),
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
