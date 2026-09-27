import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import '../data/takeout_account_repository.dart';
import '../data/takeout_repository.dart';
import '../domain/takeout_removal.dart';
import 'saved_takeouts.dart';
import 'takeout_selection_notifier.dart';

part 'takeout_remover.g.dart';

/// Removes saved takeouts, with the queued deletions and sign-ins only they
/// had. A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class TakeoutRemover extends _$TakeoutRemover {
  @override
  void build() {}

  /// What removing [takeoutId] would remove: its data, and the queued
  /// deletions and sign-ins of its channels that no other saved takeout has.
  Future<TakeoutRemoval> planRemoval(String takeoutId) async {
    final saved = await ref.read(savedTakeoutsProvider.future);
    final summary = saved.firstWhere((s) => s.id == takeoutId);
    final elsewhere = {
      for (final other in saved)
        if (other.id != takeoutId) ...other.channelIds,
    };
    final orphaned = summary.channelIds.difference(elsewhere);
    final queue = await ref.read(deletionQueueProvider.future);
    final signIns = await ref.read(savedSignInsProvider.future);
    return TakeoutRemoval(
      summary: summary,
      orphanedChannelIds: orphaned,
      queuedCount: queue
          .where((i) => orphaned.contains(i.authorChannelId))
          .length,
      signInIds: signIns.keys.toSet().intersection(orphaned),
    );
  }

  /// Removes a takeout as [removal] describes. If it was the one shown, shows
  /// the most recently exported one left, or none.
  Future<void> removeTakeout(TakeoutRemoval removal) async {
    final takeoutId = removal.summary.id;
    await ref.read(takeoutRepositoryProvider).clearCsvs(takeoutId);
    await ref
        .read(deletionQueueProvider.notifier)
        .removeForChannels(removal.orphanedChannelIds);
    await ref.read(savedSignInsProvider.notifier).removeAll(removal.signInIds);
    await ref
        .read(takeoutAccountRepositoryProvider)
        .clearViewedChannelId(takeoutId);
    ref.invalidate(savedTakeoutsProvider);

    final selection = ref.read(takeoutSelectionProvider.notifier);
    if ((await ref.read(takeoutSelectionProvider.future))?.takeoutId !=
        takeoutId) {
      return;
    }
    final remaining = await ref.read(savedTakeoutsProvider.future);
    if (remaining.isEmpty) {
      await selection.clear();
    } else {
      await selection.select(remaining.first.id);
    }
  }
}
