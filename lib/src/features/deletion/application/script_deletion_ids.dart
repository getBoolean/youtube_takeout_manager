import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../domain/deletion_targets.dart';

part 'script_deletion_ids.g.dart';

/// The comments and live chats picked for script-based deletion via My
/// Activity, each under its kind. Used to pass data to the
/// ScriptDeletionScreen since large ID sets can't be passed via route
/// parameters. Clears when another channel is viewed, whose items these
/// aren't.
@Riverpod(keepAlive: true)
class ScriptDeletionIds extends _$ScriptDeletionIds {
  @override
  DeletionTargets build() {
    ref.watch(viewedChannelIdProvider);
    return const DeletionTargets();
  }

  void set(DeletionTargets targets) {
    state = targets;
  }

  /// Narrows the script to [ids], e.g. the ones that failed, to run again.
  void keepOnly(Set<String> ids) {
    state = state.only(ids);
  }

  void clear() {
    state = const DeletionTargets();
  }
}

/// How many of the script's live chats may be membership events or
/// already-deleted messages, going by the viewed takeout's text.
@riverpod
int scriptPossibleMembershipEvents(Ref ref) => ref
    .watch(scriptDeletionIdsProvider)
    .possibleMembershipEventsIn(
      ref.watch(viewedTakeoutProvider).value?.liveChats ?? const [],
    );
