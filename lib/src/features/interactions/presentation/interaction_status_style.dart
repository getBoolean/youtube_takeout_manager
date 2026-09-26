import 'package:flutter/material.dart';

import '../domain/interaction_status.dart';

/// How an item's status shows in its list.
extension InteractionStatusStyle on InteractionStatus {
  /// Replaces the item's own icon; null while active.
  IconData? get icon => switch (this) {
    InteractionStatus.deleted => Icons.delete_outline,
    InteractionStatus.failed => Icons.error_outline,
    InteractionStatus.queued => Icons.schedule,
    InteractionStatus.active => null,
  };

  /// The colour of [icon]; null while active.
  Color? color(ColorScheme scheme) => switch (this) {
    InteractionStatus.deleted || InteractionStatus.failed => scheme.error,
    InteractionStatus.queued => scheme.tertiary,
    InteractionStatus.active => null,
  };
}
