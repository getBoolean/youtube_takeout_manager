import 'package:auto_route/auto_route.dart';
import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_host.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_search_config.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/legacy_takeout_migration.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../../application/channel_providers.dart';
import '../../application/cross_channel_search_providers.dart';
import '../../application/selection_providers.dart';
import '../../domain/channel.dart';
import '../../domain/search_result_item.dart';
import '../selection_bars.dart';
import '../skeleton.dart';
import 'channel_list_header.dart';
import 'channel_tile.dart';
import 'cross_channel_result_tile.dart';
import 'no_takeout_views.dart';
import 'section_header.dart';

const _searchBarPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

/// The app bar's search row: a [SearchBar] (56 tall) plus its padding.
const _searchBarHeight = 56.0 + 16;

@RoutePage()
class ChannelListScreen extends ConsumerWidget {
  const ChannelListScreen({super.key});

  /// Before any takeout is shown: [body] centered and scrollable, under the
  /// account button.
  Widget _buildWithoutTakeout(Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        actions: const [AccountButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takeoutAsync = ref.watch(viewedTakeoutProvider);

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

    // Keeps the list's selection mode while the screen is open, loading
    // included. It leaves by itself when the search clears.
    final inSelection = ref.watch(selectionModeProvider());

    if (takeoutAsync.hasError) {
      return _buildWithoutTakeout(
        TakeoutLoadFailed(error: takeoutAsync.error!),
      );
    }
    final queue = DeletionQueueHost.of(context);
    if (takeoutAsync.hasValue && takeoutAsync.value == null) {
      // Data saved before takeouts were kept per account may be moving
      // into one. Only while nothing is selected: its failure stays, and an
      // import replaces that data.
      final migration = ref.watch(legacyTakeoutMigrationProvider);
      if (migration.hasError) {
        return _buildWithoutTakeout(TakeoutLoadFailed(error: migration.error!));
      }
      if (migration.isLoading) return queue.wrap(const _LoadingSkeleton());
      return _buildWithoutTakeout(const TakeoutImportPrompt());
    }

    if (isLoading) {
      return queue.wrap(const _LoadingSkeleton());
    }

    final hasResults = filteredChannels.isNotEmpty || searchItems.isNotEmpty;

    return queue.wrap(
      Scaffold(
        appBar: SelectionAppBar(
          title: const Text('Channels'),
          actions: [...queue.appBarActions, const AccountButton()],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(_searchBarHeight),
            child: Stack(
              children: [
                Padding(
                  padding: _searchBarPadding,
                  child: EmojiSearchBar(
                    hintText: 'Search channels and comments...',
                    emojis: EmojiSearchConfig(
                      groups: ref.watch(allChannelEmojiGroupsProvider),
                      standardEmojis: ref.watch(allUsedUnicodeEmojisProvider),
                    ),
                    onQueryChanged: (value) => ref
                        .read(channelSearchQueryProvider.notifier)
                        .update(value),
                  ),
                ),
                // Overlaid on the bar's bottom edge so it doesn't change the
                // bar's height.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Cue.onToggle(
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
                ),
              ],
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChannelListHeader(
              query: query,
              channelCount: filteredChannels.length,
              matchCount: searchItems.length,
            ),
            Expanded(
              child: !hasResults
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
            ),
          ],
        ),
        bottomNavigationBar: SelectionBottomBar(queueBar: queue.bottomBar),
      ),
    );
  }

  /// Channels first (prioritized), then the comments and live chats that
  /// match the search.
  Widget _buildResultsList({
    required List<Channel> channels,
    required List<SearchResultItem> items,
    required String query,
    required bool inSelection,
  }) {
    return CustomScrollView(
      // Back at the top when a search starts or ends.
      key: ValueKey(query.isEmpty),
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
            child: SectionHeader(label: 'Comments & live chats'),
          ),
        if (items.isNotEmpty)
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => CrossChannelResultTile(
              key: ValueKey(
                '${items[index].item.kind}:${items[index].item.id}',
              ),
              result: items[index],
              query: query,
            ),
          ),
      ],
    );
  }
}

/// The channel list's app bar and rows while the takeout loads.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        actions: const [AccountButton()],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(_searchBarHeight),
          child: Padding(
            padding: _searchBarPadding,
            child: SearchBar(
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
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SkeletonAvatar(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 140, height: 14),
                    SizedBox(height: 6),
                    SkeletonLine(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
