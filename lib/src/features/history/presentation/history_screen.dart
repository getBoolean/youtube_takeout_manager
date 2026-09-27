import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/counted_tab_bar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_placement.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_search_bar.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../application/history_channel_filter.dart';
import '../application/history_providers.dart';
import '../application/history_search_query.dart';
import '../application/takeout_history_notifier.dart';
import '../domain/history_days.dart';
import '../domain/takeout_history.dart';
import '../domain/watched_channels.dart';
import 'history_actions.dart';
import 'history_day_list.dart';
import 'search_entry_tile.dart';
import 'top_channels_list.dart';
import 'watch_entry_tile.dart';

/// The selected takeout's watch and search history, as its own screen.
@RoutePage()
class HistoryScreen extends HookWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Deep-link guard: ensure back navigation lands somewhere sensible.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.router.canPop()) {
          context.router.replaceAll([
            const ChannelListRoute(),
            const HistoryRoute(),
          ]);
        }
      });
      return null;
    }, const []);

    return HistoryPage(
      leading: context.router.canPop()
          ? null
          : BackButton(
              onPressed: () =>
                  context.router.replaceAll([const ChannelListRoute()]),
            ),
    );
  }
}

/// The history screen's page: tabs of watched videos, searches and the
/// channels watched most, under one search.
class HistoryPage extends HookConsumerWidget {
  /// Shown before the title, e.g. a back button when nothing's behind it.
  final Widget? leading;

  const HistoryPage({super.key, this.leading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3);
    final queue = DeletionQueuePlacement.of(context);
    final historyAsync = ref.watch(takeoutHistoryProvider);
    final history = historyAsync.value;
    final hasHistory = history != null && !history.isEmpty;

    final Widget body;
    if (historyAsync.hasError) {
      body = EmptyState(
        icon: Icons.error_outline,
        message: "History couldn't be loaded: ${historyAsync.error}",
      );
    } else if (!historyAsync.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else if (history == null) {
      body = const EmptyState(
        icon: Icons.history,
        message: 'Import a takeout to see its watch and search history.',
      );
    } else if (history.isEmpty) {
      body = const EmptyState(
        key: noHistoryKey,
        icon: Icons.history,
        message:
            'This takeout has no watch or search history. Include YouTube '
            'history when exporting from Google Takeout. Takeouts added '
            'before history could be read need adding again.',
      );
    } else {
      body = _HistoryBody(history: history, tabController: tabController);
    }

    return queue.wrap(
      Scaffold(
        appBar: AppBar(
          leading: leading,
          title: const Text('History'),
          actions: queue.appBarActions,
          bottom: hasHistory ? _HistoryTabBar(tabController) : null,
        ),
        body: body,
        bottomNavigationBar: queue.bottomBar,
      ),
    );
  }

  /// Shown when the takeout has no history.
  static const noHistoryKey = ValueKey('history-none');
}

/// Watched, Searches and Channels, each with how many match the search.
class _HistoryTabBar extends ConsumerWidget implements PreferredSizeWidget {
  final TabController controller;

  const _HistoryTabBar(this.controller);

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  static int _count(List<HistoryDay> days) =>
      days.fold(0, (sum, day) => sum + day.indices.length);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CountedTabBar(
      controller: controller,
      tabs: [
        CountedTab(
          icon: Icons.history,
          label: 'Watched',
          count: _count(ref.watch(watchDaysProvider)),
        ),
        CountedTab(
          icon: Icons.search,
          label: 'Searches',
          count: _count(ref.watch(searchDaysProvider)),
        ),
        CountedTab(
          icon: Icons.leaderboard_outlined,
          label: 'Channels',
          count: ref.watch(filteredWatchedChannelsProvider).length,
        ),
      ],
    );
  }
}

class _HistoryBody extends HookConsumerWidget {
  final TakeoutHistory history;
  final TabController tabController;

  const _HistoryBody({required this.history, required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchList = useMemoized(StickyGroupedListController.new);
    useEffect(() => watchList.dispose, [watchList]);
    final searchList = useMemoized(StickyGroupedListController.new);
    useEffect(() => searchList.dispose, [searchList]);
    final watchScroll = useScrollController();
    final searchScroll = useScrollController();
    final highlightedWatch = useState<int?>(null);
    final highlightedSearch = useState<int?>(null);

    void toTop(ScrollController scroll) {
      if (scroll.hasClients) scroll.jumpTo(0);
    }

    ref.listen(historySearchQueryProvider, (_, _) {
      toTop(watchScroll);
      toTop(searchScroll);
    });
    ref.listen(historyChannelFilterProvider, (_, _) => toTop(watchScroll));

    final query = ref.watch(historySearchQueryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: EmojiSearchBar(
            hintText: 'Search history...',
            onQueryChanged: (q) =>
                ref.read(historySearchQueryProvider.notifier).update(q),
            trailing: [
              _JumpToDateButton(
                tabController: tabController,
                onJump: (tab, index) async {
                  final (list, highlighted) = tab == 0
                      ? (watchList, highlightedWatch)
                      : (searchList, highlightedSearch);
                  highlighted.value = index;
                  Future<bool> reveal() => list.revealItem(
                    index,
                    gap: 0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                  // A far jump lands on an estimate first; once rows near
                  // it are measured, a second one is exact.
                  if (!await reveal()) await reveal();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _WatchedTab(
                history: history,
                query: query,
                controller: watchList,
                scrollController: watchScroll,
                highlighted: highlightedWatch,
              ),
              _SearchesTab(
                history: history,
                query: query,
                controller: searchList,
                scrollController: searchScroll,
                highlighted: highlightedSearch,
              ),
              TopChannelsTab(
                query: query,
                onPick: (channel) {
                  ref.read(historyChannelFilterProvider.notifier).show(channel);
                  tabController.animateTo(0);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Picks a day and jumps the open tab's list to it, or the nearest older
/// day with entries.
class _JumpToDateButton extends HookConsumerWidget {
  final TabController tabController;

  /// Jumps tab [tab]'s list to its entry at [index].
  final Future<void> Function(int tab, int index) onJump;

  const _JumpToDateButton({required this.tabController, required this.onJump});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(tabController);
    final tab = tabController.index;
    final days = switch (tab) {
      0 => ref.watch(watchDaysProvider),
      1 => ref.watch(searchDaysProvider),
      _ => const <HistoryDay>[],
    };
    return IconButton(
      icon: const Icon(Icons.event),
      tooltip: 'Jump to a day',
      onPressed: days.isEmpty
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: days.first.day,
                firstDate: days.last.day,
                lastDate: days.first.day,
              );
              if (picked == null) return;
              final day = dayGroupFor(days, picked);
              if (day != null) await onJump(tab, day.indices.first);
            },
    );
  }
}

class _WatchedTab extends ConsumerWidget {
  final TakeoutHistory history;
  final String query;
  final StickyGroupedListController controller;
  final ScrollController scrollController;
  final ValueNotifier<int?> highlighted;

  const _WatchedTab({
    required this.history,
    required this.query,
    required this.controller,
    required this.scrollController,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(watchDaysProvider);
    final channel = ref.watch(historyChannelFilterProvider);

    Future<void> act(int index) async {
      final watch = history.watches[index];
      final action = await showWatchActionsSheet(context, watch);
      if (!context.mounted) return;
      switch (action) {
        case WatchAction.open:
          await openExternally(watch.url);
        case WatchAction.showChannel:
          ref
              .read(historyChannelFilterProvider.notifier)
              .show(HistoryChannel.of(watch)!);
        case WatchAction.openChannel:
          await openExternally(watch.channelUrl!);
        case WatchAction.copyLink:
          await copyToClipboard(context, watch.url, 'Link');
        case null:
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (channel != null) _ChannelFilterChip(channel: channel),
        Expanded(
          child: days.isEmpty
              ? EmptyState(
                  icon: Icons.history,
                  message: history.watches.isEmpty
                      ? 'This takeout has no watch history.'
                      : 'No watched videos match.',
                )
              : HistoryDayList(
                  days: days,
                  controller: controller,
                  scrollController: scrollController,
                  noun: 'video',
                  highlighted: highlighted.value,
                  onHighlightDone: () => highlighted.value = null,
                  entryBuilder: (context, index) => WatchEntryTile(
                    watch: history.watches[index],
                    query: query,
                    onTap: () => act(index),
                  ),
                ),
        ),
      ],
    );
  }
}

/// The channel the watches are narrowed to, removable.
class _ChannelFilterChip extends ConsumerWidget {
  final HistoryChannel channel;

  const _ChannelFilterChip({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: InputChip(
          avatar: ChannelAvatar(name: channel.title, radius: 12),
          label: Text(channel.title, overflow: TextOverflow.ellipsis),
          deleteButtonTooltipMessage: 'Show every channel',
          onDeleted: () =>
              ref.read(historyChannelFilterProvider.notifier).clear(),
        ),
      ),
    );
  }
}

class _SearchesTab extends ConsumerWidget {
  final TakeoutHistory history;
  final String query;
  final StickyGroupedListController controller;
  final ScrollController scrollController;
  final ValueNotifier<int?> highlighted;

  const _SearchesTab({
    required this.history,
    required this.query,
    required this.controller,
    required this.scrollController,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(searchDaysProvider);

    Future<void> act(int index) async {
      final search = history.searches[index];
      final action = await showSearchActionsSheet(context, search);
      if (!context.mounted) return;
      switch (action) {
        case SearchAction.search:
          await openExternally(search.url.toString());
        case SearchAction.copy:
          await copyToClipboard(context, search.query, 'Search');
        case null:
          break;
      }
    }

    if (days.isEmpty) {
      return EmptyState(
        icon: Icons.search,
        message: history.searches.isEmpty
            ? 'This takeout has no search history.'
            : 'No searches match.',
      );
    }
    return HistoryDayList(
      days: days,
      controller: controller,
      scrollController: scrollController,
      noun: 'search',
      plural: 'searches',
      highlighted: highlighted.value,
      onHighlightDone: () => highlighted.value = null,
      entryBuilder: (context, index) => SearchEntryTile(
        search: history.searches[index],
        query: query,
        onTap: () => act(index),
      ),
    );
  }
}

/// The channels watched most, narrowed by the search. Picking one shows its
/// watches.
class TopChannelsTab extends ConsumerWidget {
  final String query;
  final ValueChanged<HistoryChannel> onPick;

  const TopChannelsTab({super.key, required this.query, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(filteredWatchedChannelsProvider);
    if (channels.isEmpty) {
      return EmptyState(
        icon: Icons.leaderboard_outlined,
        message: query.isEmpty
            ? 'No channels in this watch history.'
            : 'No channels match.',
      );
    }
    return TopChannelsList(channels: channels, query: query, onPick: onPick);
  }
}
