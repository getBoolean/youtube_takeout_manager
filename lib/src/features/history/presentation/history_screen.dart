import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/counted_tab_bar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_search_bar.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../application/history_channel_filter.dart';
import '../application/history_providers.dart';
import '../application/history_removed_filter.dart';
import '../application/history_search_query.dart';
import '../application/takeout_history_notifier.dart';
import '../domain/history_days.dart';
import '../domain/loaded_history.dart';
import '../domain/watched_channels.dart';
import 'history_actions.dart';
import 'history_day_list.dart';
import 'search_entry_tile.dart';
import 'top_channels_list.dart';
import 'watch_entry_tile.dart';
import 'removed_badge.dart';

/// The selected takeout's watch and search history, as its own screen.
/// Without a takeout there's none to show, so it goes back to the channels.
@RoutePage()
class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final history = ref.watch(takeoutHistoryProvider);
    final noTakeout = history.hasValue && history.value == null;
    useEffect(() {
      if (!noTakeout) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.router.replaceAll([const ChannelListRoute()]);
        }
      });
      return null;
    }, [noTakeout]);

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

  /// Shown when the takeout has no history.
  static const noHistoryKey = ValueKey('history-none');

  /// The toggle for, and the chip of, the filter for what was removed from
  /// YouTube's history.
  static const removedToggleKey = ValueKey('history-removed-toggle');
  static const removedChipKey = ValueKey('history-removed-chip');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3);
    final historyAsync = ref.watch(takeoutHistoryProvider);
    final loaded = historyAsync.value;
    final hasHistory = loaded != null && !loaded.history.isEmpty;

    final Widget body;
    if (historyAsync.hasError) {
      body = EmptyState(
        icon: Icons.error_outline,
        message: "History couldn't be loaded: ${historyAsync.error}",
      );
    } else if (!historyAsync.hasValue || loaded == null) {
      // Without a takeout the screen is on its way back to the channels.
      body = const Center(child: CircularProgressIndicator());
    } else if (!hasHistory) {
      body = const EmptyState(
        key: noHistoryKey,
        icon: Icons.history,
        message:
            'This takeout has no watch or search history. Include YouTube '
            'history when exporting from Google Takeout. Takeouts added '
            'before history could be read need adding again.',
      );
    } else {
      body = _HistoryBody(loaded: loaded, tabController: tabController);
    }

    // The deletion queue stays with the channels: history is only read.
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: const Text('History'),
        bottom: hasHistory ? _HistoryTabBar(tabController) : null,
      ),
      body: body,
    );
  }
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
  final LoadedHistory loaded;
  final TabController tabController;

  const _HistoryBody({required this.loaded, required this.tabController});

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
    ref.listen(historyRemovedFilterProvider, (_, _) {
      toTop(watchScroll);
      toTop(searchScroll);
    });

    // Every channel's picture, most watched first; signed out, none are
    // fetched, so this runs again on signing in.
    final session = ref.watch(readSessionChannelIdProvider);
    useEffect(() {
      final ids = [
        for (final c in loaded.watchedChannels) ?c.channel.channelId,
      ];
      if (ids.isNotEmpty) {
        unawaited(
          ref.read(channelThumbnailFetcherProvider.notifier).fetchNow(ids),
        );
      }
      return null;
    }, [loaded, session]);

    final query = ref.watch(historySearchQueryProvider);

    // The lists come a frame after the rest of the screen, so opening it
    // never builds everything in one frame.
    final showLists = useState(false);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showLists.value = true;
      });
      return null;
    }, const []);

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
              _RemovedToggle(loaded: loaded, tabController: tabController),
              _JumpToDateButton(
                tabController: tabController,
                lists: (watches: watchList, searches: searchList),
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
                  if (!await reveal() && !await reveal()) {
                    highlighted.value = null;
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: !showLists.value
              ? const SizedBox.shrink()
              : TabBarView(
                  controller: tabController,
                  children: [
                    _WatchedTab(
                      loaded: loaded,
                      query: query,
                      controller: watchList,
                      scrollController: watchScroll,
                      highlighted: highlightedWatch,
                    ),
                    _SearchesTab(
                      loaded: loaded,
                      query: query,
                      controller: searchList,
                      scrollController: searchScroll,
                      highlighted: highlightedSearch,
                    ),
                    TopChannelsTab(
                      query: query,
                      onPick: (channel) {
                        ref
                            .read(historyChannelFilterProvider.notifier)
                            .show(channel);
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

/// Picks a day with history and jumps the open tab's list to it. The
/// calendar opens on the day at the top of the list.
class _JumpToDateButton extends HookConsumerWidget {
  final TabController tabController;
  final ({
    StickyGroupedListController watches,
    StickyGroupedListController searches,
  })
  lists;

  /// Jumps tab [tab]'s list to its entry at [index].
  final Future<void> Function(int tab, int index) onJump;

  const _JumpToDateButton({
    required this.tabController,
    required this.lists,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(tabController);
    final tab = tabController.index;
    final (days, list) = switch (tab) {
      0 => (ref.watch(watchDaysProvider), lists.watches),
      1 => (ref.watch(searchDaysProvider), lists.searches),
      _ => (const <HistoryDay>[], null),
    };
    return IconButton(
      icon: const Icon(Icons.event),
      tooltip: 'Jump to a day',
      onPressed: days.isEmpty || list == null
          ? null
          : () async {
              final dayKeys = {for (final day in days) day.dayKey};
              final shown = list.topGroupKey;
              final picked = await showDatePicker(
                context: context,
                initialDate: days
                    .firstWhere(
                      (day) => day.dayKey == shown,
                      orElse: () => days.first,
                    )
                    .day,
                firstDate: days.last.day,
                lastDate: days.first.day,
                selectableDayPredicate: (date) => dayKeys.contains(
                  date.year * 10000 + date.month * 100 + date.day,
                ),
              );
              if (picked == null) return;
              final day = dayGroupFor(days, picked);
              if (day != null) await onJump(tab, day.indices.first);
            },
    );
  }
}

/// The filters on above a list, each a chip that removes it: only entries
/// removed from YouTube's history, and the channel watched videos are
/// narrowed to. Nothing while none are on.
class _ActiveFilters extends ConsumerWidget {
  final HistoryChannel? channel;

  const _ActiveFilters({this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final removedOnly = ref.watch(historyRemovedFilterProvider);
    final channel = this.channel;
    final pictures = ref.watch(channelThumbnailsProvider).value ?? const {};
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !removedOnly && channel == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (removedOnly)
                    InputChip(
                      key: HistoryPage.removedChipKey,
                      avatar: const Icon(removedIcon, size: 18),
                      label: const Tooltip(
                        message: 'Only what was removed from YouTube history',
                        child: Text('Removed'),
                      ),
                      deleteButtonTooltipMessage: 'Show everything',
                      onDeleted: () => ref
                          .read(historyRemovedFilterProvider.notifier)
                          .set(false),
                    ),
                  if (channel != null)
                    InputChip(
                      avatar: ChannelAvatar(
                        name: channel.title,
                        thumbnailUrl: pictures[channel.channelId],
                        radius: 12,
                      ),
                      label: Text(
                        channel.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteButtonTooltipMessage: 'Show every channel',
                      onDeleted: () => ref
                          .read(historyChannelFilterProvider.notifier)
                          .clear(),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Shows only what was removed from YouTube's history, in the watched
/// videos or searches. Only there when the history has some.
class _RemovedToggle extends HookConsumerWidget {
  final LoadedHistory loaded;
  final TabController tabController;

  const _RemovedToggle({required this.loaded, required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(tabController);
    if (loaded.removedWatchCount + loaded.removedSearchCount == 0) {
      return const SizedBox.shrink();
    }
    final applies = switch (tabController.index) {
      0 => loaded.removedWatchCount > 0,
      1 => loaded.removedSearchCount > 0,
      _ => false,
    };
    final on = ref.watch(historyRemovedFilterProvider);
    return IconButton(
      key: HistoryPage.removedToggleKey,
      isSelected: on,
      icon: const Icon(Icons.auto_delete_outlined),
      selectedIcon: const Icon(removedIcon),
      tooltip: on
          ? 'Show everything'
          : 'Show only what was removed from YouTube history',
      // Always turns it off, even where nothing was removed.
      onPressed: applies || on
          ? () => ref.read(historyRemovedFilterProvider.notifier).set(!on)
          : null,
    );
  }
}

class _WatchedTab extends ConsumerWidget {
  final LoadedHistory loaded;
  final String query;
  final StickyGroupedListController controller;
  final ScrollController scrollController;
  final ValueNotifier<int?> highlighted;

  const _WatchedTab({
    required this.loaded,
    required this.query,
    required this.controller,
    required this.scrollController,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(watchDaysProvider);
    final channel = ref.watch(historyChannelFilterProvider);
    final pictures = ref.watch(channelThumbnailsProvider).value ?? const {};
    final removedOnly = ref.watch(historyRemovedFilterProvider);
    final watches = loaded.history.watches;

    Future<void> act(int index) async {
      final watch = watches[index];
      final action = await showWatchActionsSheet(
        context,
        watch,
        channelPicture: pictures[watch.channelId],
      );
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
        _ActiveFilters(channel: channel),
        Expanded(
          child: days.isEmpty
              ? EmptyState(
                  icon: Icons.history,
                  message: watches.isEmpty
                      ? 'This takeout has no watch history.'
                      : 'No watched videos match.',
                )
              : LayoutBuilder(
                  // Every row is as wide, so it's measured once, not per row.
                  builder: (context, constraints) {
                    final thumbnail = WatchEntryTile.thumbnailSizeFor(
                      constraints.maxWidth,
                    );
                    return HistoryDayList(
                      days: days,
                      controller: controller,
                      scrollController: scrollController,
                      noun: 'video',
                      highlighted: highlighted.value,
                      onHighlightDone: () => highlighted.value = null,
                      entryBuilder: (context, index) => WatchEntryTile(
                        watch: watches[index],
                        query: query,
                        thumbnailSize: thumbnail,
                        channelPicture: pictures[watches[index].channelId],
                        markRemoved: !removedOnly,
                        onTap: () => act(index),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchesTab extends ConsumerWidget {
  final LoadedHistory loaded;
  final String query;
  final StickyGroupedListController controller;
  final ScrollController scrollController;
  final ValueNotifier<int?> highlighted;

  const _SearchesTab({
    required this.loaded,
    required this.query,
    required this.controller,
    required this.scrollController,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(searchDaysProvider);
    final removedOnly = ref.watch(historyRemovedFilterProvider);
    final searches = loaded.history.searches;

    Future<void> act(int index) async {
      final search = searches[index];
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ActiveFilters(),
        Expanded(
          child: days.isEmpty
              ? EmptyState(
                  icon: Icons.search,
                  message: searches.isEmpty
                      ? 'This takeout has no search history.'
                      : 'No searches match.',
                )
              : HistoryDayList(
                  days: days,
                  controller: controller,
                  scrollController: scrollController,
                  noun: 'search',
                  plural: 'searches',
                  highlighted: highlighted.value,
                  onHighlightDone: () => highlighted.value = null,
                  entryBuilder: (context, index) => SearchEntryTile(
                    search: searches[index],
                    query: query,
                    markRemoved: !removedOnly,
                    onTap: () => act(index),
                  ),
                ),
        ),
      ],
    );
  }
}

/// The channels watched most, narrowed by the search. Picking one shows its
/// videos.
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
    return TopChannelsList(
      channels: channels,
      pictures: ref.watch(channelThumbnailsProvider).value ?? const {},
      query: query,
      onPick: onPick,
    );
  }
}
