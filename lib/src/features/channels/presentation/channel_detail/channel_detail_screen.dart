import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/common_widgets/empty_state.dart';
import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_button.dart';
import 'package:youtube_takeout_manager/src/features/comments/application/comment_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_layout.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/debounced_search_bar.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/application/live_chat_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import '../../application/channel_content_search_query.dart';
import '../../application/channel_providers.dart';
import 'channel_actions_header.dart';
import 'channel_app_bar.dart';
import 'channel_deletion_bar.dart';
import 'channel_loading_skeleton.dart';
import 'comment_list_view.dart';
import 'live_chat_list_view.dart';
import 'search_options_menu_button.dart';

@RoutePage()
class ChannelDetailScreen extends HookConsumerWidget {
  final String channelId;
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
    final selectionMode = useState(false);
    final commentScrollController = useScrollController();
    final liveChatScrollController = useScrollController();
    final tabController = useTabController(initialLength: 2);

    // Deep-link guard: ensure back navigation lands somewhere sensible.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.router.canPop()) {
          context.router.replaceAll([
            const HomeRoute(),
            const ChannelListRoute(),
            ChannelDetailRoute(channelId: channelId),
          ]);
        }
      });
      return null;
    }, const []);

    // Resolve scroll target from query params. Split per kind so each list
    // view only sees its own id; the other sees null.
    final isCommentTarget = targetKind == 'comment' && targetId != null;
    final isLiveChatTarget = targetKind == 'liveChat' && targetId != null;
    final commentTargetId = isCommentTarget ? targetId : null;
    final liveChatTargetId = isLiveChatTarget ? targetId : null;

    // One-shot: when arriving with a scroll target, switch to the matching
    // tab. The caller clears the search query before navigating, so the
    // list views' search-reset listener doesn't undo the scroll target.
    useEffect(() {
      if (!isCommentTarget && !isLiveChatTarget) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tabController.animateTo(isCommentTarget ? 0 : 1);
      });
      return null;
    }, [channelId, targetKind, targetId]);

    final queue = DeletionQueueHost.of(context, currentChannelId: channelId);
    final takeoutAsync = ref.watch(takeoutProvider);
    if (takeoutAsync.isLoading ||
        (!takeoutAsync.hasValue && !takeoutAsync.hasError)) {
      return queue.wrap(const ChannelLoadingSkeleton());
    }

    final commentCount = ref.watch(
      channelCommentsProvider(channelId).select((l) => l.length),
    );
    final liveChatCount = ref.watch(
      channelLiveChatsProvider(channelId).select((l) => l.length),
    );
    final hasSelection = ref.watch(
      deletionSetProvider.select((s) => s.isNotEmpty),
    );
    final channel = ref.watch(channelByIdProvider(channelId));
    final channelName = channel?.channelTitle ?? 'Unknown Channel';

    final hasComments = commentCount > 0;
    final hasLiveChats = liveChatCount > 0;
    final useTabs = hasComments && hasLiveChats;

    final lists = useTabs
        ? TabBarView(
            controller: tabController,
            children: [
              ChannelCommentListView(
                channelId: channelId,
                selectionMode: selectionMode,
                scrollController: commentScrollController,
                initialScrollTarget: commentTargetId,
              ),
              ChannelLiveChatListView(
                channelId: channelId,
                selectionMode: selectionMode,
                scrollController: liveChatScrollController,
                initialScrollTarget: liveChatTargetId,
              ),
            ],
          )
        : hasComments
        ? ChannelCommentListView(
            channelId: channelId,
            selectionMode: selectionMode,
            scrollController: commentScrollController,
            initialScrollTarget: commentTargetId,
          )
        : ChannelLiveChatListView(
            channelId: channelId,
            selectionMode: selectionMode,
            scrollController: liveChatScrollController,
            initialScrollTarget: liveChatTargetId,
          );

    final header = ChannelActionsHeader(
      channelId: channelId,
      selectionMode: selectionMode,
    );

    // One search bar above both tabs, so comments and live chats share the
    // same query text.
    final body = hasComments || hasLiveChats
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: DebouncedSearchBar(
                  hintText: useTabs
                      ? 'Search comments and live chats...'
                      : hasComments
                      ? 'Search comments...'
                      : 'Search live chats...',
                  emojis: EmojiSearchConfig(
                    groups: ref.watch(channelEmojiGroupsProvider(channelId)),
                    standardEmojis: ref.watch(
                      channelUnicodeEmojisProvider(channelId),
                    ),
                  ),
                  onQueryChanged: (v) => ref
                      .read(channelContentSearchQueryProvider.notifier)
                      .update(v),
                  trailing: const [SearchOptionsMenuButton()],
                ),
              ),
              Expanded(child: lists),
            ],
          )
        : Column(
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

    final scheme = Theme.of(context).colorScheme;
    final inSelection = selectionMode.value;
    return queue.wrap(
      Scaffold(
        appBar: AppBar(
          titleSpacing: inSelection ? null : 0,
          title: inSelection
              ? ChannelSelectionTitle(channelId: channelId)
              : ChannelTitle(
                  channelName: channelName,
                  thumbnailUrl: channel?.thumbnailUrl,
                  channelUrl:
                      channel?.channelUrl ??
                      'https://www.youtube.com/channel/$channelId',
                ),
          backgroundColor: inSelection ? scheme.secondaryContainer : null,
          foregroundColor: inSelection ? scheme.onSecondaryContainer : null,
          leading: inSelection
              ? CloseButton(
                  onPressed: () {
                    selectionMode.value = false;
                    ref.read(deletionSetProvider.notifier).clear();
                  },
                )
              : !context.router.canPop()
              ? BackButton(
                  onPressed: () => context.router.replaceAll([
                    const HomeRoute(),
                    const ChannelListRoute(),
                  ]),
                )
              : null,
          actions: inSelection
              ? [ChannelSelectAllAction(channelId: channelId)]
              : [
                  ...queue.appBarActions,
                  // Leaves room for the back button in the narrowest windows;
                  // it's still on Home.
                  if (MediaQuery.sizeOf(context).width >= 200)
                    const AccountButton(),
                ],
          bottom: useTabs
              ? ChannelTabBar(
                  controller: tabController,
                  commentCount: commentCount,
                  liveChatCount: liveChatCount,
                )
              : null,
        ),
        body: body,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBottomBar(
              visible: inSelection && hasSelection,
              child: ChannelDeletionBar(
                channelId: channelId,
                selectionMode: selectionMode,
              ),
            ),
            if (queue.bottomBar case final bar? when !inSelection) bar,
          ],
        ),
      ),
    );
  }
}
