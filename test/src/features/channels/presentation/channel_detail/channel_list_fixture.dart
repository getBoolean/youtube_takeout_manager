import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/grouped_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/selection_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/video_group.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/interaction_list_view.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

/// Deterministic channel detail data shared by the channel list tests.
///
/// Dates are local (not UTC) so `formatDateTime`'s `toLocal()` is a no-op and
/// the shown dates don't depend on the machine's timezone.
const channelId = 'ch';

const _commentCounts = [
  3, 1, 6, 2, 4, 10, 1, 3, 5, 2, 7, 1, 2, 3, 4, //
  2, 1, 5, 3, 2, 6, 1, 2, 4, 3, 1, 2, 3, 2, 4,
];

String groupTitle(int i) => i.isEven
    ? 'Video $i with a considerably longer title that wraps onto two lines'
    : 'Video $i';

String _commentText(int g, int j) => (g + j).isEven
    ? 'Comment $j in group $g'
    : 'Comment $j in group $g, which is long enough to wrap onto a second '
          'line of the tile';

GroupType _groupType(int i) => switch (i) {
  28 => GroupType.post,
  29 => GroupType.orphaned,
  _ => GroupType.video,
};

VideoGroup<Comment> _commentGroup(int g, List<Comment> items) => switch (g) {
  28 => VideoGroup.post('p28', items),
  29 => VideoGroup.other(items),
  _ => VideoGroup.video('v$g', items),
};

String commentId(int g, int j) => 'c${g}_$j';

final commentGroups = [
  for (var g = 0; g < _commentCounts.length; g++)
    _commentGroup(g, [
      for (var j = 0; j < _commentCounts[g]; j++)
        Comment(
          commentId: commentId(g, j),
          channelId: channelId,
          createdAt: DateTime(2024, 6, 30 - g, 12 - j),
          price: 0,
          videoId: _groupType(g) == GroupType.video ? 'v$g' : null,
          postId: _groupType(g) == GroupType.post ? 'p28' : null,
          rawCommentText: '{"text": "${_commentText(g, j)}"}',
          displayText: _commentText(g, j),
        ),
    ]),
];

const _liveChatCounts = [4, 2, 8, 3, 6, 1, 5, 3, 7, 2];

String liveChatId(int g, int j) => 'l${g}_$j';

final liveChatGroups = [
  for (var g = 0; g < _liveChatCounts.length; g++)
    VideoGroup<LiveChat>.video('v$g', [
      for (var j = 0; j < _liveChatCounts[g]; j++)
        LiveChat(
          liveChatId: liveChatId(g, j),
          channelId: channelId,
          createdAt: DateTime(2024, 6, 30 - g, 12, 59 - j),
          // Every third chat is a superchat, in two different tiers.
          price: j % 3 == 1 ? (g.isEven ? 5000000 : 100000000) : 0,
          currencyCode: j % 3 == 1 ? 'USD' : null,
          videoId: 'v$g',
          rawText: '{"text": "Live chat $j in group $g"}',
          displayText: 'Live chat $j in group $g',
        ),
    ]),
];

final videos = {
  for (var g = 0; g < 28; g++)
    'v$g': Video(videoId: 'v$g', channelId: channelId, title: groupTitle(g)),
};

class _FakeVideoMetadata extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value(videos);
}

class _FakeDeletedIds extends DeletedIds {
  @override
  Future<Map<QueueItemKind, Set<String>>> build() async => {
    QueueItemKind.comment: {commentId(0, 1)},
    QueueItemKind.liveChat: {liveChatId(0, 2)},
  };
}

/// With [fakeQueue] false, what's queued and failed comes from the real
/// deletion queue instead.
List<Override> fixtureOverrides({bool fakeQueue = true}) => [
  filteredGroupedChannelInteractionsProvider(
    QueueItemKind.comment,
    channelId,
  ).overrideWithValue(commentGroups),
  filteredGroupedChannelInteractionsProvider(
    QueueItemKind.liveChat,
    channelId,
  ).overrideWithValue(liveChatGroups),
  videoMetadataProvider.overrideWith(_FakeVideoMetadata.new),
  deletedIdsProvider.overrideWith(_FakeDeletedIds.new),
  if (fakeQueue) ...[
    queuedIdsProvider(
      QueueItemKind.comment,
    ).overrideWithValue({commentId(2, 0)}),
    failedIdsProvider(
      QueueItemKind.comment,
    ).overrideWithValue({commentId(2, 1)}),
    queuedIdsProvider(
      QueueItemKind.liveChat,
    ).overrideWithValue({liveChatId(1, 0)}),
    failedIdsProvider(
      QueueItemKind.liveChat,
    ).overrideWithValue({liveChatId(1, 1)}),
  ],
];

enum ListKind { comments, liveChats }

class ListHarness {
  final ScrollController scroll;
  final ProviderContainer container;

  ListHarness(this.scroll, this.container);

  /// Whether the list is in selection mode.
  bool get selecting =>
      container.read(selectionModeProvider(channelId: channelId));
}

/// Pumps one of the channel detail list views at 800x900 the way
/// `ChannelDetailScreen` hosts it.
Future<ListHarness> pumpList(
  WidgetTester tester, {
  ListKind kind = ListKind.comments,
  String? initialScrollTarget,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  final container = ProviderContainer(overrides: fixtureOverrides());
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: ChannelInteractionListView(
            kind: switch (kind) {
              ListKind.comments => QueueItemKind.comment,
              ListKind.liveChats => QueueItemKind.liveChat,
            },
            channelId: channelId,
            scrollController: scroll,
            initialScrollTarget: initialScrollTarget,
          ),
        ),
      ),
    ),
  );
  // Let the async fakes (video metadata stream, deleted ids) resolve.
  await tester.pump();
  await tester.pump();
  return ListHarness(scroll, container);
}

/// Scrolls in steps of at most 150px, one 16ms frame per step, the way wheel
/// or drag input arrives.
Future<void> scrollTo(
  WidgetTester tester,
  ScrollController controller,
  double target,
) async {
  while ((controller.offset - target).abs() > 0.5) {
    final before = controller.offset;
    final next = before < target
        ? (before + 150).clamp(before, target)
        : (before - 150).clamp(target, before);
    controller.jumpTo(next);
    await tester.pump(const Duration(milliseconds: 16));
    if ((controller.offset - before).abs() < 0.5) break;
  }
}
