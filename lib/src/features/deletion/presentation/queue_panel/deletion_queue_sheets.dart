import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/deletion_queue_pane_expanded.dart';
import 'deletion_queue_layout.dart';
import 'deletion_queue_panel.dart';

/// Opens the deletion queue as a full-height side sheet over the screen.
Future<void> showDeletionQueueSideSheet(
  BuildContext context, {
  String? currentChannelId,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (sheetContext, _, _) => _CloseWhenDocked(
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: SizedBox(
          width: min(
            deletionQueuePaneWidth,
            MediaQuery.sizeOf(sheetContext).width,
          ),
          height: double.infinity,
          child: Material(
            elevation: 1,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.horizontal(
                start: Radius.circular(16),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: DeletionQueuePanel(
                currentChannelId: currentChannelId,
                headerAction: CloseButton(
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final fromEnd = Directionality.of(context) == TextDirection.rtl
          ? -1.0
          : 1.0;
      return SlideTransition(
        position: Tween(begin: Offset(fromEnd, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
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
    builder: (sheetContext) => _CloseWhenDocked(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: DeletionQueuePanel(
          currentChannelId: currentChannelId,
          headerAction: CloseButton(
            onPressed: () => Navigator.pop(sheetContext),
          ),
        ),
      ),
    ),
  );
}

/// Closes the queue's side sheet or bottom sheet around it once the window
/// is wide enough to dock the queue, and expands the docked pane so the
/// queue stays in view.
///
/// Waits while something the user opened from the sheet, like the Delete
/// dialog, is on top of it, rather than pulling the sheet out from under it.
class _CloseWhenDocked extends ConsumerStatefulWidget {
  final Widget child;

  const _CloseWhenDocked({required this.child});

  @override
  ConsumerState<_CloseWhenDocked> createState() => _CloseWhenDockedState();
}

class _CloseWhenDockedState extends ConsumerState<_CloseWhenDocked> {
  var _closing = false;

  @override
  Widget build(BuildContext context) {
    final docked = deletionQueueLayoutOf(context) == DeletionQueueLayout.docked;
    // Depending on the route rebuilds this when it's back on top.
    final onTop = ModalRoute.of(context)?.isCurrent ?? false;
    if (docked && onTop && !_closing) {
      _closing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(deletionQueuePaneExpandedProvider.notifier).set(true);
        Navigator.of(context).pop();
      });
    }
    return widget.child;
  }
}

/// A callback that brings the deletion queue into view, or null if it's
/// already in view.
///
/// Everything it needs is looked up now, so it still works after [context]
/// is gone, e.g. from a snackbar action.
VoidCallback? deletionQueueOpener(BuildContext context, WidgetRef ref) {
  final navigator = Navigator.of(context);

  switch (deletionQueueLayoutOf(context)) {
    case DeletionQueueLayout.docked:
      if (ref.read(deletionQueuePaneExpandedProvider)) return null;
      final pane = ref.read(deletionQueuePaneExpandedProvider.notifier);
      return () => pane.set(true);
    case DeletionQueueLayout.strip || DeletionQueueLayout.appBarIcon:
      return () {
        if (navigator.mounted) showDeletionQueueSideSheet(navigator.context);
      };
    case DeletionQueueLayout.bottomBar:
      return () {
        if (navigator.mounted) showDeletionQueueSheet(navigator.context);
      };
  }
}
