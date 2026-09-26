import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import '../data/takeout_repository.dart';
import '../data/takeout_summary_parser.dart';
import '../domain/takeout_channel.dart';
import 'takeout_notifier.dart';
import 'viewed_takeout_providers.dart';

part 'saved_takeouts.g.dart';

/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data. Removing one is `TakeoutRemover`'s.
@Riverpod(keepAlive: true)
class SavedTakeouts extends _$SavedTakeouts {
  @override
  Future<List<TakeoutSummary>> build() async {
    final summaries = await loadTakeoutSummaries(
      ref.watch(takeoutRepositoryProvider),
      loaded: ref.watch(takeoutProvider).value,
    );
    final titles = ref.watch(signedInChannelTitlesProvider);
    final thumbnails = ref.watch(ownChannelThumbnailsProvider);
    return [
      for (final s in summaries)
        s.copyWith(
          channels: withThumbnails(withTitles(s.channels, titles), thumbnails),
        ),
    ]..sort(_newestFirst);
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
