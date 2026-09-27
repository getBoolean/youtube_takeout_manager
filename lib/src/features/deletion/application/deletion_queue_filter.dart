import '../domain/deletion_item_status.dart';
import 'deletion_queue_counts.dart';

/// Which of the viewed channel's queue items the queue lists.
enum DeletionQueueFilter {
  all,
  waiting,
  failed,
  done;

  bool shows(DeletionItemStatus status) => switch (this) {
    all => true,
    waiting => status.isWaiting,
    failed => status.isFailed,
    done => status.isDone,
  };

  /// How many items in [counts] this shows.
  int countIn(DeletionQueueCounts counts) => switch (this) {
    all => counts.total,
    waiting => counts.waiting,
    failed => counts.failed,
    done => counts.done,
  };
}
