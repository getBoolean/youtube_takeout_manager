import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_item_actions.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

final _comment = Comment(
  commentId: 'c1',
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  videoId: 'v1',
  rawCommentText: '{"text":"hi"}',
  displayText: 'hi',
);

final _chat = LiveChat(
  liveChatId: 'l1',
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  videoId: 'v1',
  rawText: '{"text":"yo"}',
  displayText: 'yo',
);

class _RecordingDeletedIds extends DeletedIds {
  final marked = <DeletionTargets>[];

  @override
  Future<Map<QueueItemKind, Set<String>>> build() async => {};

  @override
  Future<void> markDeleted(DeletionTargets targets) async =>
      marked.add(targets);
}

void main() {
  /// Opens [item]'s sheet from a button, and returns what it picked.
  Future<Future<ItemAction?>> openSheet(
    WidgetTester tester,
    Interaction item, {
    InteractionStatus status = InteractionStatus.active,
  }) async {
    late Future<ItemAction?> picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => picked = showItemActionsSheet(
                context,
                item: item,
                status: status,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('the sheet returns the pick', (tester) async {
    final picked = await openSheet(tester, _comment);

    await tester.tap(find.text('Add to deletion queue'));
    await tester.pumpAndSettle();

    expect(await picked, ItemAction.queue);
  });

  testWidgets('a queued item offers to leave the queue, not to be queued or '
      'removed', (tester) async {
    await openSheet(tester, _comment, status: InteractionStatus.queued);

    expect(find.text('Remove from queue'), findsOneWidget);
    expect(find.text('Add to deletion queue'), findsNothing);
    expect(find.text('Remove locally'), findsNothing);
  });

  for (final (item, name) in [(_comment, 'comments'), (_chat, 'live chats')]) {
    testWidgets('removing locally says it is for $name', (tester) async {
      await openSheet(tester, item);
      expect(find.textContaining(name), findsOneWidget);
    });
  }

  testWidgets('removing locally asks first, then marks the item deleted', (
    tester,
  ) async {
    final deletedIds = _RecordingDeletedIds();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deletedIdsProvider.overrideWith(() => deletedIds)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => runItemAction(
                  context,
                  ref,
                  _chat,
                  ItemAction.removeLocally,
                ),
                child: const Text('Remove'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(deletedIds.marked, isEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Remove'),
      ),
    );
    await tester.pumpAndSettle();

    expect(deletedIds.marked.single.liveChatIds, {'l1'});
  });
}
