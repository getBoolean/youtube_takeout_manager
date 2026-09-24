import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'script_deletion_ids.g.dart';

/// Holds the set of comment and/or live chat IDs selected for script-based
/// deletion via My Activity. Used to pass data to the ScriptDeletionScreen
/// since large ID sets can't be passed via route parameters.
@Riverpod(keepAlive: true)
class ScriptDeletionIds extends _$ScriptDeletionIds {
  @override
  Set<String> build() => {};

  void set(Set<String> ids) {
    state = ids;
  }

  void clear() {
    state = {};
  }
}
