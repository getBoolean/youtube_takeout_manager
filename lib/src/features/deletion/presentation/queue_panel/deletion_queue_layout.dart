import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'deletion_queue_pane.dart';
import 'deletion_queue_panel.dart';
import 'deletion_queue_summary_bar.dart';

part 'deletion_queue_layout.g.dart';

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

/// Whether the docked queue pane is expanded rather than collapsed to a
/// strip. Shared by every screen that docks it.
@Riverpod(keepAlive: true)
class DeletionQueuePaneExpanded extends _$DeletionQueuePaneExpanded {
  @override
  bool build() => true;

  void set(bool expanded) => state = expanded;
}

/// The pieces a screen's [Scaffold] needs to show the deletion queue in the
/// layout that fits the window.
class DeletionQueueHost {
  final DeletionQueueLayout layout;

  /// The channel the screen shows, whose items are listed first.
  final String? currentChannelId;

  DeletionQueueHost.of(BuildContext context, {this.currentChannelId})
    : layout = deletionQueueLayoutOf(context);

  /// [content] with the docked pane or strip beside it.
  Widget body(Widget content) => switch (layout) {
    DeletionQueueLayout.docked || DeletionQueueLayout.strip => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: content),
        const VerticalDivider(width: 1),
        if (layout == DeletionQueueLayout.docked)
          DeletionQueuePane(currentChannelId: currentChannelId)
        else
          const DeletionQueueStrip(),
      ],
    ),
    _ => content,
  };

  /// The side sheet, for layouts that open one.
  Widget? get endDrawer => switch (layout) {
    DeletionQueueLayout.strip ||
    DeletionQueueLayout.appBarIcon => DeletionQueueDrawer(
      currentChannelId: currentChannelId,
    ),
    _ => null,
  };

  List<Widget> get appBarActions => layout == DeletionQueueLayout.appBarIcon
      ? const [DeletionQueueIconButton()]
      : const [];

  /// The phone summary bar, for the bottom of the screen.
  Widget? get bottomBar => layout == DeletionQueueLayout.bottomBar
      ? DeletionQueueSummaryBar(currentChannelId: currentChannelId)
      : null;
}

/// Opens the deletion queue as a bottom sheet.
Future<void> showDeletionQueueSheet(
  BuildContext context, {
  String? currentChannelId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.85,
      child: DeletionQueuePanel(
        currentChannelId: currentChannelId,
        headerAction: CloseButton(onPressed: () => Navigator.pop(sheetContext)),
      ),
    ),
  );
}

/// A callback that brings the deletion queue into view on the screen around
/// [context], or null if it's already in view or the screen has no queue.
///
/// Everything it needs is looked up now, so it still works after [context]
/// is gone, e.g. from a snackbar action.
VoidCallback? deletionQueueOpener(BuildContext context, WidgetRef ref) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold == null) return null;

  switch (deletionQueueLayoutOf(context)) {
    case DeletionQueueLayout.docked:
      if (ref.read(deletionQueuePaneExpandedProvider)) return null;
      final pane = ref.read(deletionQueuePaneExpandedProvider.notifier);
      return () => pane.set(true);
    case DeletionQueueLayout.strip || DeletionQueueLayout.appBarIcon:
      if (!scaffold.hasEndDrawer) return null;
      return () {
        if (scaffold.mounted) scaffold.openEndDrawer();
      };
    case DeletionQueueLayout.bottomBar:
      return () {
        if (scaffold.mounted) showDeletionQueueSheet(scaffold.context);
      };
  }
}
