import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/selection_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_result_item.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/cross_channel_result_tile.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

const _channelId = 'UCchannel';

final _comment = Comment(
  commentId: 'queued',
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  rawCommentText: '{"text":"a queued comment"}',
  displayText: 'a queued comment',
);

void main() {
  Future<ProviderContainer> pumpTile(
    WidgetTester tester, {
    required bool selecting,
  }) async {
    final container = ProviderContainer(
      overrides: [
        viewedChannelIdProvider.overrideWithValue('UCme'),
        channelByIdProvider(_channelId).overrideWithValue(null),
        interactionStatusesProvider(
          QueueItemKind.comment,
        ).overrideWithValue(const InteractionStatuses(queued: {'queued'})),
      ],
    );
    addTearDown(container.dispose);
    container.listen(selectionModeProvider(), (_, _) {});
    if (selecting) container.read(selectionModeProvider().notifier).enter();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Material(
            child: CrossChannelResultTile(
              result: SearchResultItem(_comment, channelId: _channelId),
              query: 'queued',
            ),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('a queued item shows the queued icon, and the chevron to open '
      'it', (tester) async {
    await pumpTile(tester, selecting: false);

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(
      find.descendant(
        of: find.byWidget(tile.leading!),
        matching: find.byIcon(Icons.schedule),
      ),
      findsOneWidget,
    );
    expect((tile.trailing! as Icon).icon, Icons.chevron_right);
    expect(find.byIcon(Icons.comment_outlined), findsNothing);
  });

  testWidgets("a queued item can't be picked by tapping or long-pressing", (
    tester,
  ) async {
    final container = await pumpTile(tester, selecting: true);
    container.listen(deletionSetProvider, (_, _) {});

    await tester.tap(find.byType(ListTile));
    await tester.pump();
    expect(container.read(deletionSetProvider), isEmpty);

    // Its checkbox stays enabled, and does nothing either.
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.onChanged, isNotNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(container.read(deletionSetProvider), isEmpty);

    expect(tester.widget<ListTile>(find.byType(ListTile)).onLongPress, isNull);
    await tester.longPress(find.byType(ListTile));
    await tester.pump();
    expect(container.read(deletionSetProvider), isEmpty);
  });
}
