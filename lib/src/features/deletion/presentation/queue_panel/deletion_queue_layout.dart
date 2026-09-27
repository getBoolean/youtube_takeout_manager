import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';

/// The width of the docked queue pane, and the most its side sheet takes.
const deletionQueuePaneWidth = 360.0;

/// Where a screen shows the deletion queue.
enum DeletionQueueLayout {
  /// A pane docked beside the content, collapsible to a strip.
  docked,

  /// A strip beside the content that opens the queue as a side sheet.
  strip,

  /// An app bar button that opens the queue as a side sheet.
  appBarIcon,

  /// A summary bar along the bottom that opens the queue as a bottom sheet.
  bottomBar,
}

/// Phones get the bottom bar; everything else, however narrow, gets a pane,
/// strip or app bar button.
DeletionQueueLayout deletionQueueLayoutFor({
  required double width,
  required TargetPlatform platform,
}) {
  final mobile =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  if (mobile && width < compactWidthBreakpoint) {
    return DeletionQueueLayout.bottomBar;
  }
  if (width >= expandedWidthBreakpoint) return DeletionQueueLayout.docked;
  if (width >= compactWidthBreakpoint) return DeletionQueueLayout.strip;
  return DeletionQueueLayout.appBarIcon;
}

DeletionQueueLayout deletionQueueLayoutOf(BuildContext context) =>
    deletionQueueLayoutFor(
      width: MediaQuery.sizeOf(context).width,
      // On web this is the browser's OS, so phone browsers count as phones.
      platform: defaultTargetPlatform,
    );
