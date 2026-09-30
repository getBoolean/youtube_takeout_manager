import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/adaptive_segmented_button.dart';
import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/share_bar.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/viewing_mix.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../domain/watch_filters.dart';

/// The filters of the watched videos, as set in the Filters modal.
typedef WatchFilterDraft = ({
  SubscriptionFilter subscription,
  ShowFilter shorts,
  ShowFilter music,
  ChannelSelection selection,
});

/// Filters that narrow nothing.
const WatchFilterDraft noWatchFilters = (
  subscription: SubscriptionFilter.all,
  shorts: ShowFilter.all,
  music: ShowFilter.all,
  selection: ChannelSelection(),
);

/// Asks for the filters of the watched videos, starting from [initial]:
/// subscriptions when [hasSubscriptions], Shorts when [hasShorts] (with
/// [shortsNote] under them), YouTube Music when [hasMusic], the categories
/// of the viewing [mix] once any channel has one, and any of [channels].
/// Null when closed without showing or clearing.
Future<WatchFilterDraft?> showHistoryFilterSheet(
  BuildContext context, {
  required WatchFilterDraft initial,
  required List<FilterChannel> channels,
  required bool hasSubscriptions,
  required bool hasShorts,
  String? shortsNote,
  required bool hasMusic,
  List<CategoryShare> mix = const [],
}) => WoltModalSheet.show<WatchFilterDraft>(
  context: context,
  modalDecorator: (child) => _DraftScope(initial: initial, child: child),
  pageListBuilder: (_) => [
    SliverWoltModalSheetPage(
      topBarTitle: Semantics(
        header: true,
        child: Text(
          'Filters',
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: const Padding(
        padding: EdgeInsetsDirectional.only(end: 8),
        child: CloseButton(),
      ),
      stickyActionBar: const _Actions(),
      mainContentSliversBuilder: (_) => [
        SliverToBoxAdapter(
          child: _Sections(
            hasSubscriptions: hasSubscriptions,
            hasShorts: hasShorts,
            shortsNote: shortsNote,
            hasMusic: hasMusic,
            mix: mix,
          ),
        ),
        _ChannelsSliver(channels: channels),
        // Room for the actions, which stay over the bottom of the page.
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    ),
  ],
);

/// Keys of the Filters modal's parts.
abstract final class HistoryFilterSheet {
  static const subscriptionSectionKey = ValueKey('filters-subscriptions');
  static const shortsSectionKey = ValueKey('filters-shorts');
  static const musicSectionKey = ValueKey('filters-music');
  static const categoriesSectionKey = ValueKey('filters-categories');
  static const showKey = ValueKey('filters-show');
  static const clearKey = ValueKey('filters-clear');

  static ValueKey<String> subscriptionKey(SubscriptionFilter filter) =>
      ValueKey('filters-subscriptions-${filter.name}');
  static ValueKey<String> shortsKey(ShowFilter filter) =>
      ValueKey('filters-shorts-${filter.name}');
  static ValueKey<String> musicKey(ShowFilter filter) =>
      ValueKey('filters-music-${filter.name}');
  static ValueKey<String> channelKey(String channelKey) =>
      ValueKey('filters-channel-$channelKey');
  static ValueKey<String> categoryKey(CategoryPick pick) =>
      ValueKey('filters-category-${pick.label}');
  static ValueKey<String> categoryExpandKey(String parent) =>
      ValueKey('filters-category-expand-$parent');
}

/// Holds the filters being set, for the page and its actions alike.
class _DraftScope extends HookWidget {
  final WatchFilterDraft initial;
  final Widget child;

  const _DraftScope({required this.initial, required this.child});

  @override
  Widget build(BuildContext context) =>
      _Draft(notifier: useValueNotifier(initial), child: child);
}

class _Draft extends InheritedNotifier<ValueNotifier<WatchFilterDraft>> {
  const _Draft({required super.notifier, required super.child});

  static ValueNotifier<WatchFilterDraft> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Draft>()!.notifier!;
}

/// The subscription, Shorts and Music filters, each a row of choices, and
/// the categories, for what the takeout has.
class _Sections extends StatelessWidget {
  final bool hasSubscriptions;
  final bool hasShorts;
  final String? shortsNote;
  final bool hasMusic;
  final List<CategoryShare> mix;

  const _Sections({
    required this.hasSubscriptions,
    required this.hasShorts,
    this.shortsNote,
    required this.hasMusic,
    this.mix = const [],
  });

  @override
  Widget build(BuildContext context) {
    final draft = _Draft.of(context);
    final value = draft.value;
    final tiny = isTinyWidth(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSubscriptions)
            _Section(
              key: HistoryFilterSheet.subscriptionSectionKey,
              title: 'Subscriptions',
              child: AdaptiveSegmentedButton<SubscriptionFilter>(
                segments: [
                  for (final (filter, label) in [
                    (SubscriptionFilter.all, 'All'),
                    (SubscriptionFilter.subscribed, 'Subscribed'),
                    (SubscriptionFilter.notSubscribed, 'Not subscribed'),
                  ])
                    AdaptiveSegment(
                      value: filter,
                      label: label,
                      key: HistoryFilterSheet.subscriptionKey(filter),
                    ),
                ],
                selected: value.subscription,
                onChanged: (filter) => draft.value = (
                  subscription: filter,
                  shorts: value.shorts,
                  music: value.music,
                  selection: value.selection,
                ),
              ),
            ),
          if (hasShorts)
            _Section(
              key: HistoryFilterSheet.shortsSectionKey,
              title: 'Shorts',
              note: shortsNote,
              child: AdaptiveSegmentedButton<ShowFilter>(
                segments: [
                  for (final (filter, label) in [
                    (ShowFilter.all, 'All videos'),
                    (ShowFilter.only, 'Only Shorts'),
                    (ShowFilter.hide, 'No Shorts'),
                  ])
                    AdaptiveSegment(
                      value: filter,
                      label: label,
                      key: HistoryFilterSheet.shortsKey(filter),
                    ),
                ],
                selected: value.shorts,
                onChanged: (filter) => draft.value = (
                  subscription: value.subscription,
                  shorts: filter,
                  music: value.music,
                  selection: value.selection,
                ),
              ),
            ),
          if (hasMusic)
            _Section(
              key: HistoryFilterSheet.musicSectionKey,
              title: 'YouTube Music',
              child: AdaptiveSegmentedButton<ShowFilter>(
                segments: [
                  for (final (filter, label) in [
                    (ShowFilter.all, 'Everything'),
                    (ShowFilter.only, 'Only Music'),
                    (ShowFilter.hide, 'No Music'),
                  ])
                    AdaptiveSegment(
                      value: filter,
                      label: label,
                      key: HistoryFilterSheet.musicKey(filter),
                    ),
                ],
                selected: value.music,
                onChanged: (filter) => draft.value = (
                  subscription: value.subscription,
                  shorts: value.shorts,
                  music: filter,
                  selection: value.selection,
                ),
              ),
            ),
          // Once there's anything but the uncategorized.
          if (mix.any((share) => share.pick.parent != null))
            _Section(
              key: HistoryFilterSheet.categoriesSectionKey,
              title: 'Categories',
              note: "Each one's share of the videos you watched.",
              child: _Categories(mix: mix),
            ),
        ],
      ),
    );
  }
}

/// The viewing mix, largest first, each category a row to tick with its
/// share of the watched videos; one with sub-categories opens to them, each
/// to tick alone.
class _Categories extends HookWidget {
  final List<CategoryShare> mix;

  const _Categories({required this.mix});

  @override
  Widget build(BuildContext context) {
    final draft = _Draft.of(context);
    final picks = draft.value.selection.categories;
    final open = useState(const <String>{});

    void toggle(CategoryPick pick, CategoryShare category) {
      final value = draft.value;
      draft.value = (
        subscription: value.subscription,
        shorts: value.shorts,
        music: value.music,
        selection: ChannelSelection(
          channels: value.selection.channels,
          categories: togglePick(value.selection.categories, pick, category),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in mix) ...[
          _CategoryRow(
            share: category,
            state: pickState(picks, category),
            onTap: () => toggle(category.pick, category),
            open: category.children.isEmpty
                ? null
                : open.value.contains(category.pick.parent),
            onOpen: () {
              final parent = category.pick.parent!;
              open.value = open.value.contains(parent)
                  ? ({...open.value}..remove(parent))
                  : {...open.value, parent};
            },
          ),
          if (open.value.contains(category.pick.parent))
            for (final sub in category.children)
              _CategoryRow(
                share: sub,
                state: pickState(picks, sub),
                onTap: () => toggle(sub.pick, category),
                indented: true,
              ),
        ],
      ],
    );
  }
}

/// A row of the viewing mix: a checkbox, its name, its share as a bar, and
/// the percent and how many channels it has. A category with sub-categories
/// has a button to [open] them.
class _CategoryRow extends StatelessWidget {
  final CategoryShare share;

  /// Ticked, not, or partly (null).
  final bool? state;
  final VoidCallback onTap;
  final bool indented;

  /// Whether its sub-categories show; null when it has none.
  final bool? open;
  final VoidCallback? onOpen;

  const _CategoryRow({
    required this.share,
    required this.state,
    required this.onTap,
    this.indented = false,
    this.open,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final pick = share.pick;
    final channels = formatCount(share.channelCount, 'channel');
    final animate = !MediaQuery.disableAnimationsOf(context);
    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            key: HistoryFilterSheet.categoryKey(pick),
            value: state,
            tristate: true,
            onChanged: (_) => onTap(),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsetsDirectional.only(
              start: indented && !tiny ? 24 : 0,
            ),
            title: Text(indented ? pick.shortLabel : pick.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                ShareBar(share: share.share),
                const SizedBox(height: 4),
                Semantics(
                  label:
                      '${(share.share * 100).round()} percent of the watched '
                      'videos, $channels',
                  child: ExcludeSemantics(
                    child: Text(
                      '${formatShare(share.share)} · $channels',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (open case final open?)
          IconButton(
            key: HistoryFilterSheet.categoryExpandKey(pick.parent!),
            tooltip: open
                ? 'Hide the kinds of ${pick.label}'
                : 'Show the kinds of ${pick.label}',
            onPressed: onOpen,
            icon: AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: animate
                  ? const Duration(milliseconds: 200)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.expand_more),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? note;
  final Widget child;

  const _Section({
    super.key,
    required this.title,
    this.note,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          child,
          if (note case final note?) ...[
            const SizedBox(height: 6),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The channels to pick, searchable, each a row with a checkbox. Built
/// lazily however many there are.
class _ChannelsSliver extends HookConsumerWidget {
  final List<FilterChannel> channels;

  const _ChannelsSliver({required this.channels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = _Draft.of(context);
    final query = useState('');
    final folded = foldForSearch(query.value);
    final shown = useMemoized(
      () => folded.isEmpty
          ? channels
          : [
              for (final c in channels)
                if (foldForSearch(c.channel.title).contains(folded)) c,
            ],
      [channels, folded],
    );
    final pictures = ref.watch(channelThumbnailsProvider).value ?? const {};
    final selection = draft.value.selection;
    final tiny = isTinyWidth(context);
    final theme = Theme.of(context);

    void toggle(FilterChannel c) {
      final value = draft.value;
      final picked = {...value.selection.channels};
      final key = c.channel.key;
      if (picked.remove(key) == null) picked[key] = c.channel;
      draft.value = (
        subscription: value.subscription,
        shorts: value.shorts,
        music: value.music,
        selection: ChannelSelection(channels: picked),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 0, tiny ? 8 : 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    selection.isEmpty
                        ? 'Channels'
                        : 'Channels · ${selection.channels.length} picked',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (text) => query.value = text,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: tiny ? null : const Icon(Icons.search),
                    hintText: 'Search channels',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final c = shown[i];
            final channel = c.channel;
            final detail = [
              c.count == 0 ? 'Never watched' : formatCount(c.count, 'video'),
              if (c.subscribed) 'Subscribed',
            ].join(' · ');
            return CheckboxListTile(
              key: HistoryFilterSheet.channelKey(channel.key),
              value: selection.contains(channel.key),
              onChanged: (_) => toggle(c),
              contentPadding: EdgeInsets.symmetric(horizontal: tiny ? 8 : 24),
              secondary: tiny
                  ? null
                  : ChannelAvatar(
                      name: channel.title,
                      thumbnailUrl: pictures[channel.channelId],
                      radius: 16,
                    ),
              title: Text(
                channel.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(detail),
            );
          },
        ),
      ],
    );
  }
}

/// Clearing every filter, or showing what's set; both close the modal.
class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    final draft = _Draft.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            key: HistoryFilterSheet.clearKey,
            onPressed: () => Navigator.of(context).pop(noWatchFilters),
            child: const Text('Clear all', textAlign: TextAlign.center),
          ),
          FilledButton(
            key: HistoryFilterSheet.showKey,
            onPressed: () => Navigator.of(context).pop(draft.value),
            child: const Text('Show', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
