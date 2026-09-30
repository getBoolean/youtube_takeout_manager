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
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../application/history_channel_selection.dart';
import '../application/history_grouping.dart';
import '../application/history_providers.dart';
import '../application/history_removed_filter.dart';
import '../application/history_search_query.dart';
import '../application/takeout_history_notifier.dart';
import '../application/watch_filter_providers.dart';
import '../domain/history_days.dart';
import '../domain/loaded_history.dart';
import '../domain/watch_filters.dart';
import '../domain/watched_channels.dart';
import 'history_actions.dart';
import 'history_channel_list.dart';
import 'history_day_list.dart';
import 'history_filter_sheet.dart';
import 'history_toolbar.dart';
import 'grouping_sheet.dart';
import 'on_screen_channels.dart';
import 'search_entry_tile.dart';
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

/// The history screen's page: tabs of watched videos, grouped as picked,
/// and searches, under one search.
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
    final tabController = useTabController(initialLength: 2);
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

/// Watched and Searches, each with how many match the search and filters.
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
      ],
    );
  }
}

/// The lists of watched videos, one per way of grouping them, and where
/// each is scrolled to.
typedef _WatchLists = ({
  StickyGroupedListController days,
  StickyGroupedListController months,
  StickyGroupedListController channels,
  ScrollController dayScroll,
  ScrollController monthScroll,
  ScrollController channelScroll,
});

class _HistoryBody extends HookConsumerWidget {
  final LoadedHistory loaded;
  final TabController tabController;

  const _HistoryBody({required this.loaded, required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayList = useMemoized(StickyGroupedListController.new);
    useEffect(() => dayList.dispose, [dayList]);
    final monthList = useMemoized(StickyGroupedListController.new);
    useEffect(() => monthList.dispose, [monthList]);
    // Channels start closed, so they read as a list of channels.
    final channelList = useMemoized(
      () => StickyGroupedListController(expandedByDefault: false),
    );
    useEffect(() => channelList.dispose, [channelList]);
    final searchList = useMemoized(StickyGroupedListController.new);
    useEffect(() => searchList.dispose, [searchList]);
    final lists = (
      days: dayList,
      months: monthList,
      channels: channelList,
      dayScroll: useScrollController(),
      monthScroll: useScrollController(),
      channelScroll: useScrollController(),
    );
    final searchScroll = useScrollController();
    final highlightedWatch = useState<int?>(null);
    final highlightedSearch = useState<int?>(null);

    void toTop(ScrollController scroll) {
      if (scroll.hasClients) scroll.jumpTo(0);
    }

    void watchesToTop() {
      toTop(lists.dayScroll);
      toTop(lists.monthScroll);
      toTop(lists.channelScroll);
    }

    ref.listen(historySearchQueryProvider, (_, _) {
      watchesToTop();
      toTop(searchScroll);
    });
    ref.listen(historyChannelMaskProvider, (_, _) => watchesToTop());
    ref.listen(historyShortsFilterProvider, (_, _) => watchesToTop());
    ref.listen(historyMusicFilterProvider, (_, _) => watchesToTop());
    ref.listen(historyRemovedFilterProvider, (_, _) {
      watchesToTop();
      toTop(searchScroll);
    });

    // Every channel's picture, in the order the watched videos are listed,
    // then the channels subscribed to but never watched; signed out, none
    // are fetched, so this runs again on signing in.
    final session = ref.watch(readSessionChannelIdProvider);
    final unwatched = ref.watch(
      historySubscriptionMatchProvider.select((m) => m.unwatched),
    );
    useEffect(() {
      final ids = [
        ...loaded.recentChannelIds,
        for (final channel in unwatched) ?channel.channelId,
      ];
      if (ids.isNotEmpty) {
        unawaited(
          ref.read(channelThumbnailFetcherProvider.notifier).fetchNow(ids),
        );
      }
      return null;
    }, [loaded, session, unwatched]);

    // The channels of the rows on screen go first, wherever that is.
    final onScreen = useMemoized(
      () => OnScreenChannels((ids) {
        if (!context.mounted) return;
        ref.read(channelThumbnailFetcherProvider.notifier).fetchFirst(ids);
      }),
    );
    useEffect(() => onScreen.dispose, [onScreen]);

    final query = ref.watch(historySearchQueryProvider);
    final grouping = ref.watch(historyGroupingProvider);

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
                grouping: grouping,
                lists: (days: dayList, months: monthList, searches: searchList),
                onJump: (tab, groupKey, index) async {
                  final (list, highlighted) = tab == 0
                      ? (
                          grouping == HistoryGrouping.month
                              ? monthList
                              : dayList,
                          highlightedWatch,
                        )
                      : (searchList, highlightedSearch);
                  // A collapsed group has nothing to jump to.
                  list.setExpanded(groupKey, true);
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
                      grouping: grouping,
                      lists: lists,
                      highlighted: highlightedWatch,
                      onChannelShown: onScreen.add,
                    ),
                    _SearchesTab(
                      loaded: loaded,
                      query: query,
                      controller: searchList,
                      scrollController: searchScroll,
                      highlighted: highlightedSearch,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Picks a day with history and jumps the open list to it: to the day,
/// or to its first entry in its month. The calendar opens on the day at the
/// top of the list. Only while the open list is grouped by time.
class _JumpToDateButton extends HookConsumerWidget {
  final TabController tabController;
  final HistoryGrouping grouping;
  final ({
    StickyGroupedListController days,
    StickyGroupedListController months,
    StickyGroupedListController searches,
  })
  lists;

  /// Jumps tab [tab]'s list to its entry at [index], in the group with
  /// [groupKey].
  final Future<void> Function(int tab, Object groupKey, int index) onJump;

  const _JumpToDateButton({
    required this.tabController,
    required this.grouping,
    required this.lists,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(tabController);
    final tab = tabController.index;
    final byMonth = tab == 0 && grouping == HistoryGrouping.month;
    final (days, list) = switch (tab) {
      0 when grouping == HistoryGrouping.day => (
        ref.watch(watchDaysProvider),
        lists.days,
      ),
      0 when byMonth => (ref.watch(watchDaysProvider), lists.months),
      1 => (ref.watch(searchDaysProvider), lists.searches),
      _ => (const <HistoryDay>[], null),
    };
    if (list == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.event),
      tooltip: 'Jump to a day',
      onPressed: days.isEmpty
          ? null
          : () async {
              final dayKeys = {for (final day in days) day.dayKey};
              final shown = list.topGroupKey;
              final picked = await showDatePicker(
                context: context,
                initialDate: days
                    .firstWhere(
                      (day) =>
                          day.dayKey == shown ||
                          (byMonth && day.dayKey ~/ 100 * 100 == shown),
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
              if (day == null) return;
              await onJump(
                tab,
                byMonth ? day.dayKey ~/ 100 * 100 : day.dayKey,
                day.indices.first,
              );
            },
    );
  }
}

/// The filters on above a list, each a chip that removes it: only entries
/// removed from YouTube's history, and, over the watched videos, the
/// subscription, Shorts and Music filters and the channels picked. Nothing
/// while none are on.
class _ActiveFilters extends ConsumerWidget {
  /// Whether the watched videos' filters show, not only the Removed one.
  final bool watched;

  /// Opens the filters, for the channels past the few with chips.
  final VoidCallback? onMore;

  const _ActiveFilters({this.watched = false, this.onMore});

  /// Channels past this many are summed up in one chip.
  static const _channelChips = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final removedOnly = ref.watch(historyRemovedFilterProvider);
    final subscription = watched
        ? ref.watch(historySubscriptionFilterProvider)
        : SubscriptionFilter.all;
    final shorts = watched
        ? ref.watch(historyShortsFilterProvider)
        : ShowFilter.all;
    final music = watched
        ? ref.watch(historyMusicFilterProvider)
        : ShowFilter.all;
    final channels = watched
        ? ref.watch(historyChannelSelectionProvider).channels.values.toList()
        : const <HistoryChannel>[];
    final pictures = ref.watch(channelThumbnailsProvider).value ?? const {};
    final none =
        !removedOnly &&
        subscription == SubscriptionFilter.all &&
        shorts == ShowFilter.all &&
        music == ShowFilter.all &&
        channels.isEmpty;

    Widget chip({
      Key? key,
      required Widget avatar,
      required String label,
      String? tooltip,
      required String clearTooltip,
      required VoidCallback onClear,
    }) => InputChip(
      key: key,
      avatar: avatar,
      label: Tooltip(
        message: tooltip ?? label,
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
      deleteButtonTooltipMessage: clearTooltip,
      onDeleted: onClear,
    );

    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: none
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (removedOnly)
                    chip(
                      key: HistoryPage.removedChipKey,
                      avatar: const Icon(removedIcon, size: 18),
                      label: 'Removed',
                      tooltip: 'Only what was removed from YouTube history',
                      clearTooltip: 'Show everything',
                      onClear: () => ref
                          .read(historyRemovedFilterProvider.notifier)
                          .set(false),
                    ),
                  if (subscription != SubscriptionFilter.all)
                    chip(
                      avatar: const Icon(
                        Icons.subscriptions_outlined,
                        size: 18,
                      ),
                      label: subscription == SubscriptionFilter.subscribed
                          ? 'Subscribed'
                          : 'Not subscribed',
                      clearTooltip: 'Show every channel',
                      onClear: () => ref
                          .read(historySubscriptionFilterProvider.notifier)
                          .set(SubscriptionFilter.all),
                    ),
                  if (shorts != ShowFilter.all)
                    chip(
                      avatar: const Icon(Icons.bolt_outlined, size: 18),
                      label: shorts == ShowFilter.only
                          ? 'Only Shorts'
                          : 'No Shorts',
                      clearTooltip: 'Show Shorts with the rest',
                      onClear: () => ref
                          .read(historyShortsFilterProvider.notifier)
                          .set(ShowFilter.all),
                    ),
                  if (music != ShowFilter.all)
                    chip(
                      avatar: const Icon(Icons.music_note_outlined, size: 18),
                      label: music == ShowFilter.only
                          ? 'Only Music'
                          : 'No Music',
                      clearTooltip: 'Show Music with the rest',
                      onClear: () => ref
                          .read(historyMusicFilterProvider.notifier)
                          .set(ShowFilter.all),
                    ),
                  for (final channel in channels.take(_channelChips))
                    chip(
                      avatar: ChannelAvatar(
                        name: channel.title,
                        thumbnailUrl: pictures[channel.channelId],
                        radius: 12,
                      ),
                      label: channel.title,
                      clearTooltip: channels.length == 1
                          ? 'Show every channel'
                          : 'Remove ${channel.title}',
                      onClear: () => ref
                          .read(historyChannelSelectionProvider.notifier)
                          .removeChannel(channel.key),
                    ),
                  if (channels.length > _channelChips)
                    ActionChip(
                      label: Text(
                        '+${channels.length - _channelChips} more',
                        overflow: TextOverflow.ellipsis,
                      ),
                      tooltip: 'See every channel picked',
                      onPressed: onMore,
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

/// The watched videos, grouped as picked, under the toolbar and the
/// filters on.
class _WatchedTab extends ConsumerWidget {
  final LoadedHistory loaded;
  final String query;
  final HistoryGrouping grouping;
  final _WatchLists lists;
  final ValueNotifier<int?> highlighted;

  /// Told the channel of each row as it's built.
  final ValueChanged<String?> onChannelShown;

  const _WatchedTab({
    required this.loaded,
    required this.query,
    required this.grouping,
    required this.lists,
    required this.highlighted,
    required this.onChannelShown,
  });

  /// The groupings offered.
  static const _groupings = [
    HistoryGrouping.day,
    HistoryGrouping.month,
    HistoryGrouping.channel,
  ];

  StickyGroupedListController get _list => switch (grouping) {
    HistoryGrouping.month => lists.months,
    HistoryGrouping.channel || HistoryGrouping.category => lists.channels,
    HistoryGrouping.day => lists.days,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(watchDaysProvider);
    final pictures = ref.watch(channelThumbnailsProvider).value ?? const {};
    // Fetched only signed in.
    final picturesExpected = ref.watch(readSessionChannelIdProvider) != null;
    final removedOnly = ref.watch(historyRemovedFilterProvider);
    final watches = loaded.history.watches;
    final activeFilters = [
      ref.watch(historySubscriptionFilterProvider) != SubscriptionFilter.all,
      ref.watch(historyShortsFilterProvider) != ShowFilter.all,
      ref.watch(historyMusicFilterProvider) != ShowFilter.all,
      !ref.watch(historyChannelSelectionProvider).isEmpty,
    ].where((on) => on).length;

    Future<void> act(int index) async {
      final watch = watches[index];
      final action = await showWatchActionsSheet(
        context,
        watch,
        channelPicture: pictures[watch.channelId],
        picturesExpected: picturesExpected,
      );
      if (!context.mounted) return;
      switch (action) {
        case WatchAction.open:
          await openExternally(watch.url);
        case WatchAction.showChannel:
          final channel = HistoryChannel.of(watch)!;
          ref.read(historyChannelSelectionProvider.notifier).showOnly(channel);
          lists.channels.setExpanded(channel.key, true);
        case WatchAction.openChannel:
          await openExternally(watch.channelUrl!);
        case WatchAction.copyLink:
          await copyToClipboard(context, watch.url, 'Link');
        case null:
          break;
      }
    }

    Future<void> openFilters() async {
      final draft = await showHistoryFilterSheet(
        context,
        initial: (
          subscription: ref.read(historySubscriptionFilterProvider),
          shorts: ref.read(historyShortsFilterProvider),
          music: ref.read(historyMusicFilterProvider),
          selection: ref.read(historyChannelSelectionProvider),
        ),
        channels: ref.read(historyFilterChannelsProvider),
        hasSubscriptions:
            ref.read(historySubscriptionsProvider).value?.isNotEmpty ?? false,
        hasShorts: loaded.shortCount > 0,
        hasMusic: loaded.musicCount > 0,
      );
      if (draft == null) return;
      ref
          .read(historySubscriptionFilterProvider.notifier)
          .set(draft.subscription);
      ref.read(historyShortsFilterProvider.notifier).set(draft.shorts);
      ref.read(historyMusicFilterProvider.notifier).set(draft.music);
      ref.read(historyChannelSelectionProvider.notifier).set(draft.selection);
    }

    Future<void> groupBy() async {
      final picked = await showGroupingSheet(
        context,
        current: grouping,
        available: _groupings,
      );
      if (picked != null) {
        ref.read(historyGroupingProvider.notifier).set(picked);
      }
    }

    final channelGroups = ref.watch(historyChannelGroupsProvider);
    final nothing = grouping == HistoryGrouping.channel
        ? channelGroups.groups.isEmpty
        : days.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: HistoryToolbar(
            grouping: grouping,
            activeFilters: activeFilters,
            onGroupBy: groupBy,
            onFilters: openFilters,
            onCollapseAll: () => _list.setAllExpanded(false),
            onExpandAll: () => _list.setAllExpanded(true),
          ),
        ),
        _ActiveFilters(watched: true, onMore: openFilters),
        Expanded(
          child: nothing
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
                    Widget entry(BuildContext context, int index) {
                      final watch = watches[index];
                      if (grouping != HistoryGrouping.channel) {
                        onChannelShown(watch.channelId);
                      }
                      return WatchEntryTile(
                        watch: watch,
                        query: query,
                        thumbnailSize: thumbnail,
                        channelPicture: pictures[watch.channelId],
                        picturesExpected: picturesExpected,
                        markRemoved: !removedOnly,
                        showChannel: grouping != HistoryGrouping.channel,
                        showDate: grouping != HistoryGrouping.day,
                        onTap: () => act(index),
                      );
                    }

                    return switch (grouping) {
                      HistoryGrouping.channel ||
                      HistoryGrouping.category => HistoryChannelList(
                        groups: channelGroups,
                        watchChannelIndex: loaded.watchChannelIndex,
                        controller: lists.channels,
                        scrollController: lists.channelScroll,
                        subscribedKeys: ref.watch(
                          historySubscriptionMatchProvider.select(
                            (m) => m.subscribedKeys,
                          ),
                        ),
                        pictures: pictures,
                        query: query,
                        onChannelShown: onChannelShown,
                        entryBuilder: entry,
                      ),
                      HistoryGrouping.month => HistoryDayList(
                        days: ref.watch(watchMonthsProvider),
                        controller: lists.months,
                        scrollController: lists.monthScroll,
                        noun: 'video',
                        label: formatMonth,
                        highlighted: highlighted.value,
                        onHighlightDone: () => highlighted.value = null,
                        entryBuilder: entry,
                      ),
                      HistoryGrouping.day => HistoryDayList(
                        days: days,
                        controller: lists.days,
                        scrollController: lists.dayScroll,
                        noun: 'video',
                        highlighted: highlighted.value,
                        onHighlightDone: () => highlighted.value = null,
                        entryBuilder: entry,
                      ),
                    };
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
