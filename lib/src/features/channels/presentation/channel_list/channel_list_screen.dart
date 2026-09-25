import 'package:auto_route/auto_route.dart';
import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_layout.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/select_all_toggle_button.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/debounced_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../../application/channel_providers.dart';
import '../../application/cross_channel_search_providers.dart';
import '../../domain/search_result_item.dart';
import 'channel_list_header.dart';
import 'channel_tile.dart';
import 'cross_channel_deletion_bar.dart';
import 'cross_channel_result_tile.dart';
import 'section_header.dart';

const _searchBarPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

/// The app bar's search row: a [SearchBar] (56 tall) plus its padding.
const _searchBarHeight = 56.0 + 16;

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
    final queue = DeletionQueueHost.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: _selectionMode,
      builder: (context, inSelection, _) {
        return Scaffold(
          appBar: _buildAppBar(
            context: context,
            query: query,
            searchItems: searchItems,
            inSelection: inSelection,
            queueActions: queue.appBarActions,
          ),
          endDrawer: queue.endDrawer,
          body: queue.body(Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChannelListHeader(
                query: query,
                channelCount: filteredChannels.length,
                matchCount: searchItems.length,
                selectionMode: _selectionMode,
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
          )),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBottomBar(
                visible: inSelection && hasSelection,
                child: CrossChannelDeletionBar(onExit: _exitSelectionMode),
              ),
              if (queue.bottomBar case final bar? when !inSelection) bar,
            ],
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
    required List<Widget> queueActions,
  }) {
    final progress = ref.watch(videoFetchProgressProvider);

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
      leading = CloseButton(onPressed: _exitSelectionMode);
      title = Text('$selectedCount selected');
      actions = [SelectAllToggleButton(selectableIds: deletableIds)];
    } else {
      leading = context.router.canPop()
          ? null
          : BackButton(
              onPressed: () => context.router.replaceAll([const HomeRoute()]),
            );
      title = const Text('Channels');
      actions = [...queueActions, const AccountButton()];
    }

    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      leading: leading,
      title: title,
      actions: actions,
      backgroundColor: inSelection ? scheme.secondaryContainer : null,
      foregroundColor: inSelection ? scheme.onSecondaryContainer : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_searchBarHeight),
        child: Stack(
          children: [
            Padding(
              padding: _searchBarPadding,
              child: DebouncedSearchBar(
                hintText: 'Search channels and comments...',
                emojis: EmojiSearchConfig(
                  groups: ref.watch(allChannelEmojiGroupsProvider),
                  standardEmojis: ref.watch(allUsedUnicodeEmojisProvider),
                ),
                onQueryChanged: (value) =>
                    ref.read(channelSearchQueryProvider.notifier).update(value),
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
            child: SectionHeader(label: 'Comments & live chats'),
          ),
        if (items.isNotEmpty)
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => CrossChannelResultTile(
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
