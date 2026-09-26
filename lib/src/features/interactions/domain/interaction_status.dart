/// Where an item stands in deletion, most final first.
enum InteractionStatus {
  deleted('Deleted'),
  failed('Failed'),
  queued('Queued'),
  active(null);

  const InteractionStatus(this.label);

  /// Names the status next to the item; null while active.
  final String? label;

  /// Whether the item can still be picked for deletion.
  bool get isSelectable => this == active;

  /// [text] with the status's label before it, if it has one.
  String labelled(String text) => label == null ? text : '$label • $text';
}

/// Which of one kind's items are deleted, failed or queued.
class InteractionStatuses {
  final Set<String> deleted;
  final Set<String> failed;
  final Set<String> queued;

  const InteractionStatuses({
    this.deleted = const {},
    this.failed = const {},
    this.queued = const {},
  });

  /// [id]'s status. An item in several sets shows the most final one.
  InteractionStatus of(String id) {
    if (deleted.contains(id)) return InteractionStatus.deleted;
    if (failed.contains(id)) return InteractionStatus.failed;
    if (queued.contains(id)) return InteractionStatus.queued;
    return InteractionStatus.active;
  }

  /// Items that can't be picked for deletion: deleted, failed or queued.
  Set<String> get unselectableIds => {...deleted, ...failed, ...queued};
}
