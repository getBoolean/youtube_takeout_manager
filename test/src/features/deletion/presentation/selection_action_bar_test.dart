import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';

class _RecordingQueue extends DeletionQueue {
  final enqueued = <DeletionTargets>[];

  @override
  Future<List<DeletionQueueItem>> build() async => [];

  @override
  Future<void> enqueue(
    DeletionTargets targets, {
    required String authorChannelId,
  }) async => enqueued.add(targets);
}

const _selection = DeletionTargets(
  commentSnippets: {'c1': 'hi'},
  liveChatSnippets: {'l1': 'yo'},
);

void main() {
  late _RecordingQueue queue;
  late int exits;

  Future<void> pumpBar(WidgetTester tester) async {
    queue = _RecordingQueue();
    exits = 0;
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deletionQueueProvider.overrideWith(() => queue),
          viewedChannelIdProvider.overrideWithValue('UCme'),
        ],
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SelectionActionBar(
              selection: _selection,
              onExitSelection: () => exits++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('queues the selection without asking how', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.text('Queue 2 for deletion'));
    await tester.pumpAndSettle();

    expect(queue.enqueued.single.allIds, {'c1', 'l1'});
    expect(exits, 1);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);

    // Run out the queued snackbar's force-close timer.
    await tester.pump(const Duration(seconds: 5));
  });

  Future<Map<QueueItemKind, Set<String>>> deletedIds(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(SelectionActionBar)),
      ).read(deletedIdsProvider.future);

  testWidgets('removing locally, once confirmed, marks the selection deleted '
      'and leaves selection', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.text('Remove 2 locally'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    final deleted = await deletedIds(tester);
    expect(deleted[QueueItemKind.comment], {'c1'});
    expect(deleted[QueueItemKind.liveChat], {'l1'});
    expect(exits, 1);
    expect(queue.enqueued, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('cancelling removing locally changes nothing', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.text('Remove 2 locally'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect((await deletedIds(tester)).values, everyElement(isEmpty));
    expect(exits, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
