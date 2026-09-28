import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/label_badge.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';

/// Marks a history entry a newer takeout no longer had: it was removed from
/// YouTube's history, but is kept here. Set apart from the other badges by
/// its icon and colour.
class RemovedBadge extends StatelessWidget {
  /// When a takeout first lacked it.
  final DateTime removedAt;

  const RemovedBadge({super.key, required this.removedAt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message:
          'Not in your YouTube history as of the takeout of '
          '${formatDate(removedAt)}',
      child: LabelBadge(
        'Removed from YouTube history',
        icon: Icons.history_toggle_off,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
    );
  }
}
