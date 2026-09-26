import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import '../data/takeout_account_repository.dart';
import '../data/takeout_csv_encoder.dart';
import '../data/takeout_repository.dart';
import '../data/takeout_summary_parser.dart';
import '../domain/takeout_channel.dart';
import 'takeout_notifier.dart';
import 'takeout_selection_notifier.dart';

part 'saved_takeouts.g.dart';

/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data.
@Riverpod(keepAlive: true)
class SavedTakeouts extends _$SavedTakeouts {
  @override
  Future<List<TakeoutSummary>> build() async {
    final repository = ref.watch(takeoutRepositoryProvider);
    final loaded = ref.watch(takeoutProvider).value;

    final summaries = <TakeoutSummary>[];
    for (final id in await repository.listAccountIds()) {
      if (loaded != null && loaded.id == id) {
        summaries.add(
          TakeoutSummary(
            id: id,
            channels: takeoutChannelsOf(loaded.data, takeoutId: id),
            latestExportAt: loaded.data.latestExportAt,
            countsKnown: true,
          ),
        );
      } else {
        final files = await repository.loadCsvs(id, only: isTakeoutSummaryPath);
        summaries.add(parseTakeoutSummary(id, files ?? const {}));
      }
    }
    return summaries..sort(_newestFirst);
  }

  /// What removing [takeoutId] would remove: its data, and the queued
  /// deletions and sign-ins of its channels that no other saved takeout has.
  Future<TakeoutRemoval> planRemoval(String takeoutId) async {
    final saved = await future;
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
    ref.invalidateSelf();

    final selection = ref.read(takeoutSelectionProvider.notifier);
    if ((await ref.read(takeoutSelectionProvider.future))?.takeoutId !=
        takeoutId) {
      return;
    }
    final remaining = await future;
    if (remaining.isEmpty) {
      await selection.clear();
    } else {
      await selection.select(remaining.first.id);
    }
  }
}

int _newestFirst(TakeoutSummary a, TakeoutSummary b) {
  final aTime = a.latestExportAt, bTime = b.latestExportAt;
  if (aTime != null && bTime != null && aTime != bTime) {
    return bTime.compareTo(aTime);
  }
  if ((aTime == null) != (bTime == null)) return aTime == null ? 1 : -1;
  return a.id.compareTo(b.id);
}

/// What removing a saved takeout removes.
class TakeoutRemoval {
  final TakeoutSummary summary;

  /// Its channels that no other saved takeout has, whose queued deletions
  /// and sign-ins go with it.
  final Set<String> orphanedChannelIds;
  final int queuedCount;

  /// The saved sign-ins removed with it.
  final Set<String> signInIds;

  const TakeoutRemoval({
    required this.summary,
    required this.orphanedChannelIds,
    required this.queuedCount,
    required this.signInIds,
  });
}
