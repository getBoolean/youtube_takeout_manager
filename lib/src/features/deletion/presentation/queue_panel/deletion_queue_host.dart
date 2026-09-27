import 'package:flutter/material.dart';

import 'deletion_queue_layout.dart';
import 'deletion_queue_pane.dart';
import 'deletion_queue_summary_bar.dart';

/// The pieces a screen needs to show the deletion queue in the layout that
/// fits the window.
class DeletionQueueHost {
  final DeletionQueueLayout layout;

  /// The channel the screen shows, whose items are listed first.
  final String? currentChannelId;

  DeletionQueueHost.of(BuildContext context, {this.currentChannelId})
    : layout = deletionQueueLayoutOf(context);

  /// The screen's [scaffold] with the docked pane or strip beside it, full
  /// height, app bar included.
  Widget wrap(Widget scaffold) => switch (layout) {
    DeletionQueueLayout.docked || DeletionQueueLayout.strip => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: scaffold),
        const VerticalDivider(width: 1),
        if (layout == DeletionQueueLayout.docked)
          DeletionQueuePane(currentChannelId: currentChannelId)
        else
          DeletionQueueStrip(currentChannelId: currentChannelId),
      ],
    ),
    _ => scaffold,
  };

  List<Widget> get appBarActions => layout == DeletionQueueLayout.appBarIcon
      ? [DeletionQueueIconButton(currentChannelId: currentChannelId)]
      : const [];

  /// The phone summary bar, for the bottom of the screen.
  Widget? get bottomBar => layout == DeletionQueueLayout.bottomBar
      ? DeletionQueueSummaryBar(currentChannelId: currentChannelId)
      : null;
}
