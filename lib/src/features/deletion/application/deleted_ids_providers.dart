import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import '../data/deleted_ids_repository.dart';
import '../domain/deletion_item_status.dart';
import '../domain/deletion_queue_item.dart';
import '../domain/deletion_targets.dart';
import 'deletion_queue_notifier.dart';

part 'deleted_ids_providers.g.dart';

/// The IDs of each kind's items known to be deleted.
@Riverpod(keepAlive: true)
class DeletedIds extends _$DeletedIds {
  DeletedIdsRepository get _repository =>
      ref.read(deletedIdsRepositoryProvider);

  @override
  Future<Map<QueueItemKind, Set<String>>> build() async {
    final repository = ref.watch(deletedIdsRepositoryProvider);
    return {
      for (final kind in QueueItemKind.values)
        kind: await repository.loadDeletedIds(kind),
    };
  }

  /// Remembers [targets] as deleted, so they show as deleted and can't be
  /// picked for deletion again.
  Future<void> markDeleted(DeletionTargets targets) async {
    if (targets.isEmpty) return;
    await future;
    // Read and update the state without awaiting in between, so concurrent
    // calls can't overwrite each other's IDs.
    final current = state.requireValue;
    // An untouched kind keeps its set, so what watches only that kind
    // doesn't rebuild.
    final updated = {
      for (final kind in QueueItemKind.values)
        kind: targets.idsOf(kind).isEmpty
            ? current[kind] ?? const {}
            : {...?current[kind], ...targets.idsOf(kind)},
    };
    state = AsyncData(updated);
    await Future.wait([
      for (final kind in QueueItemKind.values)
        if (targets.idsOf(kind).isNotEmpty)
          _repository.saveDeletedIds(kind, updated[kind]!),
    ]);
  }
}

// The same statuses the queue shows as waiting and failed, so an item the
// quota stopped shows as queued everywhere.
Set<String> _queueIds(
  List<DeletionQueueItem>? items,
  QueueItemKind kind,
  bool Function(DeletionItemStatus status) test,
) => {
  for (final i in items ?? const <DeletionQueueItem>[])
    if (i.itemType == kind && test(i.status)) i.itemId,
};

@riverpod
Set<String> queuedIds(Ref ref, QueueItemKind kind) =>
    _queueIds(ref.watch(deletionQueueProvider).value, kind, (s) => s.isWaiting);

@riverpod
Set<String> failedIds(Ref ref, QueueItemKind kind) =>
    _queueIds(ref.watch(deletionQueueProvider).value, kind, (s) => s.isFailed);

/// Which of [kind]'s items are deleted, failed or queued.
@riverpod
InteractionStatuses interactionStatuses(Ref ref, QueueItemKind kind) =>
    InteractionStatuses(
      deleted:
          ref.watch(deletedIdsProvider.select((s) => s.value?[kind])) ??
          const {},
      failed: ref.watch(failedIdsProvider(kind)),
      queued: ref.watch(queuedIdsProvider(kind)),
    );

/// The IDs of each kind's items bulk deletes leave out: already deleted,
/// queued or failed.
@riverpod
Map<QueueItemKind, Set<String>> excludedFromDeletionIds(Ref ref) => {
  for (final kind in QueueItemKind.values)
    kind: ref.watch(interactionStatusesProvider(kind)).unselectableIds,
};
