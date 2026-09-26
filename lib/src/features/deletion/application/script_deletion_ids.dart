import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

part 'script_deletion_ids.g.dart';

/// Holds the set of comment and/or live chat IDs selected for script-based
/// deletion via My Activity. Used to pass data to the ScriptDeletionScreen
/// since large ID sets can't be passed via route parameters. Clears when
/// another channel is viewed, whose items these aren't.
@Riverpod(keepAlive: true)
class ScriptDeletionIds extends _$ScriptDeletionIds {
  @override
  Set<String> build() {
    ref.watch(viewedChannelIdProvider);
    return {};
  }

  void set(Set<String> ids) {
    state = ids;
  }

  void clear() {
    state = {};
  }
}
