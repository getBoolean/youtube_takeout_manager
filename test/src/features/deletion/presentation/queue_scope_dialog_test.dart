import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_scope_dialog.dart';

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

const _matches = QueueScope(
  icon: Icons.search,
  title: 'Matching “cat”',
  targets: DeletionTargets(commentSnippets: {'c1': 'cat', 'c2': 'cats'}),
);

const _allComments = QueueScope(
  icon: Icons.comment_outlined,
  title: 'All comments in Ada',
  targets: DeletionTargets(
    commentSnippets: {'c1': 'cat', 'c2': 'cats', 'c3': 'dog'},
  ),
  describeCount: QueueScope.describeComments,
);

const _noLiveChats = QueueScope(
  icon: Icons.chat_bubble_outline,
  title: 'All live chats in Ada',
  targets: DeletionTargets(),
  describeCount: QueueScope.describeLiveChats,
);

/// Runs out the queued snackbar's force-close timer.
Future<void> _letSnackBarClose(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 5));

void main() {
  late _RecordingQueue queue;

  Future<void> openDialog(WidgetTester tester, List<QueueScope> scopes) async {
    queue = _RecordingQueue();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deletionQueueProvider.overrideWith(() => queue),
          viewedChannelIdProvider.overrideWithValue('UCme'),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => queueWithScopeDialog(context, ref, scopes),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows each scope with its count', (tester) async {
    await openDialog(tester, [_matches, _allComments, _noLiveChats]);

    expect(find.text('Matching “cat”'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('3 comments'), findsOneWidget);
    expect(find.text('0 live chats'), findsOneWidget);
  });

  testWidgets('groups the digits of large counts', (tester) async {
    await openDialog(tester, [
      QueueScope(
        icon: Icons.comment_outlined,
        title: 'All comments in Ada',
        targets: DeletionTargets(
          commentSnippets: {for (var i = 0; i < 1234; i++) 'c$i': null},
        ),
        describeCount: QueueScope.describeComments,
      ),
    ]);

    expect(find.text('1,234 comments'), findsOneWidget);
  });

  testWidgets('preselects the first scope and queues it', (tester) async {
    await openDialog(tester, [_matches, _allComments]);

    await tester.tap(find.text('Queue 2'));
    await tester.pumpAndSettle();

    expect(queue.enqueued.single.commentIds, {'c1', 'c2'});
    expect(find.text('2 items added to the deletion queue'), findsOneWidget);
    await _letSnackBarClose(tester);
  });

  testWidgets('queues the scope picked instead', (tester) async {
    await openDialog(tester, [_matches, _allComments]);

    await tester.tap(find.text('All comments in Ada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Queue 3'));
    await tester.pumpAndSettle();

    expect(queue.enqueued.single.commentIds, {'c1', 'c2', 'c3'});
    await _letSnackBarClose(tester);
  });

  testWidgets('skips over and disables empty scopes', (tester) async {
    await openDialog(tester, [_noLiveChats, _allComments]);

    // The empty scope isn't preselected and can't be picked.
    await tester.tap(find.text('All live chats in Ada'));
    await tester.pumpAndSettle();
    expect(find.text('Queue 3'), findsOneWidget);
  });

  testWidgets('cancelling queues nothing', (tester) async {
    await openDialog(tester, [_matches]);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(queue.enqueued, isEmpty);
    expect(find.byType(QueueScopeDialog), findsNothing);
  });
}
