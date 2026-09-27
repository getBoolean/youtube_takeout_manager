import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/selection_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_summary_bar.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_tile.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

import 'channel_list_fixture.dart' as fixture;

/// The channel list is a stand-in, so the channel's screen has somewhere to
/// go back to.
class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo(ChannelListRoute.name, builder: (_) => const SizedBox()),
      initial: true,
    ),
    AutoRoute(page: ChannelDetailRoute.page),
  ];
}

final _comments = [for (final g in fixture.commentGroups) ...g.items];
final _liveChats = [for (final g in fixture.liveChatGroups) ...g.items];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Opens the fixture channel's screen at phone size.
  Future<ProviderContainer> openChannel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        ...fixture.fixtureOverrides(fakeQueue: false),
        viewedChannelIdProvider.overrideWithValue('UCme'),
        viewedTakeoutProvider.overrideWithValue(
          AsyncData(
            TakeoutData(
              comments: _comments,
              liveChats: _liveChats,
              subscriptionsByChannelId: const {},
            ),
          ),
        ),
        channelByIdProvider(fixture.channelId).overrideWithValue(
          Channel(
            channelId: fixture.channelId,
            channelTitle: 'Ada',
            commentCount: _comments.length,
            liveChatCount: _liveChats.length,
          ),
        ),
        channelInteractionsProvider(
          QueueItemKind.comment,
          fixture.channelId,
        ).overrideWithValue(_comments),
        channelInteractionsProvider(
          QueueItemKind.liveChat,
          fixture.channelId,
        ).overrideWithValue(_liveChats),
        channelEmojiGroupsProvider(
          fixture.channelId,
        ).overrideWithValue(const []),
        channelUnicodeEmojisProvider(
          fixture.channelId,
        ).overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    final router = _Router();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router.config(),
        ),
      ),
    );
    router.push(ChannelDetailRoute(channelId: fixture.channelId)).ignore();
    await tester.pumpAndSettle();
    return container;
  }

  InteractionStatus statusOf(WidgetTester tester, String text) => tester
      .widget<InteractionTile>(
        find.ancestor(
          of: find.text(text),
          matching: find.byType(InteractionTile),
        ),
      )
      .status;

  testWidgets('picking items and queueing them leaves selection mode with '
      'the items queued', (tester) async {
    final container = await openChannel(tester);
    bool selecting() =>
        container.read(selectionModeProvider(channelId: fixture.channelId));
    expect(find.byType(DeletionQueueSummaryBar), findsOneWidget);

    await tester.longPress(find.text('Comment 0 in group 0'));
    await tester.pumpAndSettle();
    expect(selecting(), isTrue);
    await tester.tap(find.text('Comment 2 in group 0'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
    expect(find.byType(SelectionActionBar), findsOneWidget);
    expect(find.byType(DeletionQueueSummaryBar), findsNothing);

    await tester.tap(find.text('Queue 2 for deletion'));
    await tester.pumpAndSettle();

    expect(selecting(), isFalse);
    expect(container.read(deletionSetProvider), isEmpty);
    expect(statusOf(tester, 'Comment 0 in group 0'), InteractionStatus.queued);
    expect(statusOf(tester, 'Comment 2 in group 0'), InteractionStatus.queued);
    expect(find.byType(DeletionQueueSummaryBar), findsOneWidget);
    // Lets the queued snack bar close.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('going back while picking drops the picks', (tester) async {
    final container = await openChannel(tester);
    // Kept by the channel list in the app.
    container.listen(deletionSetProvider, (_, _) {});
    await tester.longPress(find.text('Comment 0 in group 0'));
    await tester.pumpAndSettle();
    expect(container.read(deletionSetProvider), isNotEmpty);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    // Lets the screen's providers be disposed.
    await tester.pump(Duration.zero);

    expect(container.read(deletionSetProvider), isEmpty);
  });
}
