import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import '../domain/deletion_targets.dart';

/// [items] as deletion targets, leaving out the IDs in [skipIds] for their
/// kind (e.g. ones already deleted, queued or failed).
DeletionTargets deletableTargets(
  Iterable<Interaction> items, {
  Map<QueueItemKind, Set<String>> skipIds = const {},
}) {
  return DeletionTargets.of(
    items.where((i) => !(skipIds[i.kind]?.contains(i.id) ?? false)),
  );
}
