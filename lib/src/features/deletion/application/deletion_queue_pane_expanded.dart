import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deletion_queue_pane_expanded.g.dart';

/// Whether the docked queue pane is expanded rather than collapsed to a
/// strip. Shared by every screen that docks it.
@Riverpod(keepAlive: true)
class DeletionQueuePaneExpanded extends _$DeletionQueuePaneExpanded {
  @override
  bool build() => true;

  void set(bool expanded) => state = expanded;
}
