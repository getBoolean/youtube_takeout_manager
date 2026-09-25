import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import 'deletion_queue_notifier.dart';

part 'deletion_queue_counts.g.dart';

/// How many queue items are waiting, failed or done.
class DeletionQueueCounts {
  /// Items the next Delete will process, including ones the quota stopped.
  static const waitingStatuses = {
    DeletionItemStatus.pending,
    DeletionItemStatus.inProgress,
    DeletionItemStatus.quotaExceeded,
  };
  static const failedStatuses = {DeletionItemStatus.failed};
  static const doneStatuses = {DeletionItemStatus.succeeded};

  final int waiting;
  final int failed;
  final int done;

  const DeletionQueueCounts({
    this.waiting = 0,
    this.failed = 0,
    this.done = 0,
  });

  factory DeletionQueueCounts.of(Iterable<DeletionQueueItem> items) {
    var waiting = 0, failed = 0, done = 0;
    for (final item in items) {
      if (waitingStatuses.contains(item.status)) waiting++;
      if (failedStatuses.contains(item.status)) failed++;
      if (doneStatuses.contains(item.status)) done++;
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
    DeletionQueueCounts.of(ref.watch(deletionQueueProvider).value ?? const []);
