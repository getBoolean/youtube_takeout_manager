import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import '../data/youtube_deletion_repository.dart';
import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import '../domain/deletion_targets.dart';
import 'deleted_ids_providers.dart';
import 'deletion_queue_notifier.dart';

part 'deletion_processing.g.dart';

enum DeletionProcessingState {
  idle,
  running,

  /// Asked to pause; stops after the item being deleted.
  pausing,
}

/// Deletes queued items through the YouTube API, one at a time, and says
/// whether it's doing so. A service: nothing depends on it, so it can read
/// any provider.
@Riverpod(keepAlive: true)
class DeletionProcessing extends _$DeletionProcessing {
  static const _delayBetweenRequests = Duration(milliseconds: 100);

  bool _isProcessing = false;
  bool _isPaused = false;

  @override
  DeletionProcessingState build() => DeletionProcessingState.idle;

  void _setProcessing({required bool processing, required bool paused}) {
    _isProcessing = processing;
    _isPaused = paused;
    state = !processing
        ? DeletionProcessingState.idle
        : paused
        ? DeletionProcessingState.pausing
        : DeletionProcessingState.running;
  }

  Future<void> startYoutubeApiProcessing({required String channelId}) async {
    if (_isProcessing) return;
    await _processQueueViaYoutubeApi(channelId);
  }

  /// Re-queues [channelId]'s items stopped by the quota, then deletes each
  /// of its pending items via the YouTube API. Other channels' items are
  /// left alone: only their own channel's sign-in can delete them.
  Future<void> processPendingViaYoutubeApi({required String channelId}) async {
    await ref
        .read(deletionQueueProvider.notifier)
        .retryQuotaExceeded(channelId: channelId);
    await startYoutubeApiProcessing(channelId: channelId);
  }

  void pauseProcessing() {
    if (!_isProcessing) return;
    _setProcessing(processing: true, paused: true);
  }

  /// Deletes [channelId]'s pending items one by one until done, paused or
  /// out of quota.
  Future<void> _processQueueViaYoutubeApi(String channelId) async {
    if (_isProcessing) return;

    // Only the channel's own sign-in may delete its items.
    final authState = ref.read(authProvider);
    if (authState == null || authState.channelId != channelId) return;
    _setProcessing(processing: true, paused: false);

    final queue = ref.read(deletionQueueProvider.notifier);
    final quota = ref.read(quotaProvider.notifier);
    final client = ref
        .read(googleAuthRepositoryProvider)
        .getAuthenticatedClient(channelId);

    try {
      await quota.resetIfNewDay();

      while (!_isPaused) {
        final canDelete = await quota.canAfford(
          QuotaOperation.deleteComment.cost,
        );
        if (!canDelete) {
          await queue.markRemainingPending(
            DeletionItemStatus.quotaExceeded,
            channelId,
          );
          break;
        }

        final items = await ref.read(deletionQueueProvider.future);
        final nextItem = items.cast<DeletionQueueItem?>().firstWhere(
          (i) =>
              i!.status == DeletionItemStatus.pending &&
              i.authorChannelId == channelId,
          orElse: () => null,
        );
        if (nextItem == null) break;

        // Mark as in progress.
        await queue.updateItem(
          nextItem.id,
          nextItem.copyWith(status: DeletionItemStatus.inProgress),
        );

        // Call the YouTube API.
        final result = await ref
            .read(youtubeDeletionRepositoryProvider)
            .deleteItem(client, nextItem.itemId);

        final now = DateTime.now().toUtc();

        if (result.succeeded) {
          final op = nextItem.itemType == QueueItemKind.comment
              ? QuotaOperation.deleteComment
              : QuotaOperation.deleteLiveChat;
          await quota.recordUsage(op);
          await queue.updateItem(
            nextItem.id,
            nextItem.copyWith(
              status: DeletionItemStatus.succeeded,
              processedAt: now,
            ),
          );

          // Persist as deleted and notify UI to re-render with deleted styling.
          await ref
              .read(deletedIdsProvider.notifier)
              .markDeleted(DeletionTargets.fromQueueItems([nextItem]));
        } else if (result.signInFailed) {
          // Not the item's fault: keep it to delete once signed in again,
          // and stop instead of failing every other item the same way.
          await queue.updateItem(nextItem.id, nextItem);
          await ref
              .read(signInServiceProvider.notifier)
              .signInFailed(channelId);
          break;
        } else if (result.quotaExceeded) {
          await queue.updateItem(
            nextItem.id,
            nextItem.copyWith(
              status: DeletionItemStatus.quotaExceeded,
              errorMessage: result.error,
              processedAt: now,
            ),
          );
          await queue.markRemainingPending(
            DeletionItemStatus.quotaExceeded,
            channelId,
          );
          break;
        } else {
          await queue.updateItem(
            nextItem.id,
            nextItem.copyWith(
              status: DeletionItemStatus.failed,
              errorMessage: result.error,
              processedAt: now,
            ),
          );
        }

        await Future.delayed(_delayBetweenRequests);
      }
    } finally {
      client.close();
      _setProcessing(processing: false, paused: _isPaused);
    }
  }
}
