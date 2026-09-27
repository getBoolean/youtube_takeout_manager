import 'package:dart_mappable/dart_mappable.dart';

part 'deletion_item_status.mapper.dart';

@MappableEnum()
enum DeletionItemStatus {
  pending,
  inProgress,
  succeeded,
  failed,
  quotaExceeded;

  /// Waiting to be deleted: queued, being deleted, or stopped by the quota
  /// until the next Delete.
  bool get isWaiting => switch (this) {
    pending || inProgress || quotaExceeded => true,
    succeeded || failed => false,
  };

  /// Waiting, and not being deleted right now, so the next Delete takes it.
  bool get isReadyToDelete => isWaiting && !isInProgress;

  bool get isInProgress => this == inProgress;
  bool get isFailed => this == failed;
  bool get isDone => this == succeeded;
}
