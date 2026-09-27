import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'channel_providers.dart';
import 'cross_channel_search_providers.dart';

part 'selection_providers.g.dart';

// Each provider here is for one screen: [channelId]'s, or the channel list's
// search results when it's null.

/// Whether the screen is picking items to delete. Each channel's screen
/// starts out of it whenever it opens.
@riverpod
class SelectionMode extends _$SelectionMode {
  @override
  bool build({String? channelId}) {
    if (channelId == null) {
      // The results vanish once the search clears, and aren't this
      // channel's once another is viewed.
      ref.watch(viewedChannelIdProvider);
      ref.listen(channelSearchQueryProvider, (_, next) {
        if (next.isEmpty && state) exit();
      });
    }
    return false;
  }

  void enter() => state = true;

  /// Leaves selection mode, dropping what was picked.
  void exit() {
    state = false;
    ref.read(deletionSetProvider.notifier).clear();
  }
}

/// The items the screen shows that can be picked: the channel's comments and
/// live chats, or the search results.
@riverpod
List<Interaction> selectionCandidates(Ref ref, {String? channelId}) {
  if (channelId == null) {
    return [
      for (final result in ref.watch(crossChannelSearchItemsProvider))
        result.item,
    ];
  }
  return [
    for (final kind in QueueItemKind.values)
      ...ref.watch(channelInteractionsProvider(kind, channelId)),
  ];
}

/// The screen's picked items.
@riverpod
DeletionTargets selectedTargets(Ref ref, {String? channelId}) {
  final selected = ref.watch(deletionSetProvider);
  return DeletionTargets.of(
    ref
        .watch(selectionCandidatesProvider(channelId: channelId))
        .where((item) => selected.contains(item.id)),
  );
}

/// The IDs of the screen's items that can still be picked: not deleted,
/// queued or failed.
@riverpod
Set<String> selectableIds(Ref ref, {String? channelId}) {
  final excluded = ref.watch(excludedFromDeletionIdsProvider);
  return {
    for (final item in ref.watch(
      selectionCandidatesProvider(channelId: channelId),
    ))
      if (!(excluded[item.kind]?.contains(item.id) ?? false)) item.id,
  };
}
