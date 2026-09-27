import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/deletion_queue_item.dart';
import 'viewed_queue_items.dart';

part 'deletion_queue_counts.g.dart';

/// How many of the viewed channel's queue items are waiting, failed or done.
class DeletionQueueCounts {
  final int waiting;
  final int failed;
  final int done;

  const DeletionQueueCounts({this.waiting = 0, this.failed = 0, this.done = 0});

  factory DeletionQueueCounts.of(Iterable<DeletionQueueItem> items) {
    var waiting = 0, failed = 0, done = 0;
    for (final item in items) {
      if (item.status.isWaiting) waiting++;
      if (item.status.isFailed) failed++;
      if (item.status.isDone) done++;
    }
    return DeletionQueueCounts(waiting: waiting, failed: failed, done: done);
  }

  int get total => waiting + failed + done;

  @override
  bool operator ==(Object other) =>
      other is DeletionQueueCounts &&
      other.waiting == waiting &&
      other.failed == failed &&
      other.done == done;

  @override
  int get hashCode => Object.hash(waiting, failed, done);
}

@riverpod
DeletionQueueCounts deletionQueueCounts(Ref ref) =>
    DeletionQueueCounts.of(ref.watch(viewedQueueItemsProvider));
