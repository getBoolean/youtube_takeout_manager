import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_placement.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_search_config.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/channel_providers.dart';
import '../../application/selection_providers.dart';
import '../selection_bars.dart';
import '../unknown_channel_hint.dart';
import 'channel_actions_header.dart';
import 'channel_app_bar.dart';
import 'channel_loading_skeleton.dart';
import 'interaction_list_view.dart';
import 'search_options_button.dart';

/// A comment or live chat to open the channel's screen scrolled to.
typedef ScrollTarget = ({QueueItemKind kind, String id});

/// The route's scroll target, or null unless [kind] names a [QueueItemKind]
/// and there's an [id].
ScrollTarget? parseScrollTarget(String? kind, String? id) {
  final itemKind = QueueItemKind.values.asNameMap()[kind];
  if (itemKind == null || id == null) return null;
  return (kind: itemKind, id: id);
}

@RoutePage()
class ChannelDetailScreen extends HookConsumerWidget {
  final String channelId;

  /// With [targetId], the item to open scrolled to: a [QueueItemKind]'s
  /// name, so links read `?targetKind=comment`.
  final String? targetKind;
  final String? targetId;

  const ChannelDetailScreen({
    super.key,
    @PathParam('channelId') required this.channelId,
    @QueryParam('targetKind') this.targetKind,
    @QueryParam('targetId') this.targetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    final scrollTarget = parseScrollTarget(targetKind, targetId);

    // Deep-link guard: ensure back navigation lands somewhere sensible.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.router.canPop()) {
          context.router.replaceAll([
            const ChannelListRoute(),
            ChannelDetailRoute(channelId: channelId),
          ]);
        }
      });
      return null;
    }, const []);

    // One-shot: when arriving with a scroll target, switch to the matching
    // tab. The caller clears the search query before navigating, so the
    // list views' search-reset listener doesn't undo the scroll target.
    useEffect(() {
      if (scrollTarget == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tabController.animateTo(switch (scrollTarget.kind) {
          QueueItemKind.comment => 0,
          QueueItemKind.liveChat => 1,
        });
      });
      return null;
    }, [channelId, targetKind, targetId]);

    // Keeps the screen's selection mode while it's open, loading included.
    ref.watch(selectionModeProvider(channelId: channelId));

    final queue = DeletionQueuePlacement.of(
      context,
      currentChannelId: channelId,
    );
    final takeoutAsync = ref.watch(viewedTakeoutProvider);
    if (takeoutAsync.isLoading ||
        (!takeoutAsync.hasValue && !takeoutAsync.hasError)) {
      return queue.wrap(const ChannelLoadingSkeleton());
    }

    final commentCount = ref.watch(
      channelInteractionsProvider(
        QueueItemKind.comment,
        channelId,
      ).select((l) => l.length),
    );
    final liveChatCount = ref.watch(
      channelInteractionsProvider(
        QueueItemKind.liveChat,
        channelId,
      ).select((l) => l.length),
    );
    final channel = ref.watch(channelByIdProvider(channelId));
    final isUnknown = channelId == unknownChannelId;

    return queue.wrap(
      Scaffold(
        appBar: SelectionAppBar(
          channelId: channelId,
          titleSpacing: 0,
          title: ChannelTitle(
            channelName: channel?.channelTitle ?? 'Unknown Channel',
            thumbnailUrl: channel?.thumbnailUrl,
            channelUrl: isUnknown
                ? null
                : channel?.channelUrl ??
                      'https://www.youtube.com/channel/$channelId',
          ),
          leading: !context.router.canPop()
              ? BackButton(
                  onPressed: () =>
                      context.router.replaceAll([const ChannelListRoute()]),
                )
              : null,
          actions: [
            ...queue.appBarActions,
            // Leaves room for the back button in the narrowest windows; it's
            // still on Channels.
            if (!isTinyWidth(context)) const AccountButton(),
          ],
          bottom: commentCount > 0 && liveChatCount > 0
              ? ChannelTabBar(
                  controller: tabController,
                  commentCount: commentCount,
                  liveChatCount: liveChatCount,
                )
              : null,
        ),
        body: ChannelDetailBody(
          channelId: channelId,
          kinds: [
            if (commentCount > 0) QueueItemKind.comment,
            if (liveChatCount > 0) QueueItemKind.liveChat,
          ],
          tabController: tabController,
          scrollTarget: scrollTarget,
        ),
        bottomNavigationBar: SelectionBottomBar(
          channelId: channelId,
          queueBar: queue.bottomBar,
        ),
      ),
    );
  }
}

/// Below a channel's app bar: its actions, one search bar, and its comments
/// and live chats.
class ChannelDetailBody extends HookConsumerWidget {
  final String channelId;

  /// The kinds of item the channel has, in tab order. When there are both,
  /// each is a tab of [tabController]'s.
  final List<QueueItemKind> kinds;
  final TabController tabController;
  final ScrollTarget? scrollTarget;

  const ChannelDetailBody({
    super.key,
    required this.channelId,
    required this.kinds,
    required this.tabController,
    this.scrollTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentScrollController = useScrollController();
    final liveChatScrollController = useScrollController();

    final actions = ChannelActionsHeader(channelId: channelId);
    final header = channelId == unknownChannelId
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: UnknownChannelHint(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              actions,
            ],
          )
        : actions;

    if (kinds.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Expanded(
            child: EmptyState(
              icon: Icons.inbox_outlined,
              message: 'No interactions found',
            ),
          ),
        ],
      );
    }

    // Keyed by kind so switching kinds starts a fresh list.
    Widget listOf(QueueItemKind kind) => ChannelInteractionListView(
      key: ValueKey(kind),
      kind: kind,
      channelId: channelId,
      scrollController: switch (kind) {
        QueueItemKind.comment => commentScrollController,
        QueueItemKind.liveChat => liveChatScrollController,
      },
      // Each list only sees its own kind's target.
      initialScrollTarget: scrollTarget?.kind == kind ? scrollTarget?.id : null,
    );

    // One search bar above both tabs, so comments and live chats share the
    // same query text.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: EmojiSearchBar(
            hintText: switch (kinds) {
              [QueueItemKind.comment] => 'Search comments...',
              [QueueItemKind.liveChat] => 'Search live chats...',
              _ => 'Search comments and live chats...',
            },
            emojis: EmojiSearchConfig(
              groups: ref.watch(channelEmojiGroupsProvider(channelId)),
              standardEmojis: ref.watch(
                channelUnicodeEmojisProvider(channelId),
              ),
            ),
            onQueryChanged: (v) =>
                ref.read(channelContentSearchQueryProvider.notifier).update(v),
            trailing: const [SearchOptionsButton()],
          ),
        ),
        Expanded(
          child: kinds.length > 1
              ? TabBarView(
                  controller: tabController,
                  children: [for (final kind in kinds) listOf(kind)],
                )
              : listOf(kinds.single),
        ),
      ],
    );
  }
}
