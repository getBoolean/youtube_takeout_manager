import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';

class _RecordingQueue extends DeletionQueue {
  final enqueued = <DeletionTargets>[];

  @override
  Future<List<DeletionQueueItem>> build() async => [];

  @override
  Future<void> enqueue(DeletionTargets targets) async => enqueued.add(targets);
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deletionQueueProvider.overrideWith(() => queue)],
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

  testWidgets('queueing is the primary action', (tester) async {
    await pumpBar(tester);

    expect(
      find.widgetWithText(FilledButton, 'Queue 2 for deletion'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Remove 2 locally'),
      findsOneWidget,
    );
  });

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
}
