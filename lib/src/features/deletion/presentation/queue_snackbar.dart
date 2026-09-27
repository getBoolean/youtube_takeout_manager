import 'package:flutter/material.dart';

/// Says items were queued, with a Show button that runs [onShow] to bring
/// the queue into view, unless it's null (the queue's already in view).
void showQueuedForDeletionSnackBar(
  BuildContext context, {
  required String message,
  VoidCallback? onShow,
}) {
  final scheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      backgroundColor: scheme.surfaceContainerHigh,
      content: Text(message, style: TextStyle(color: scheme.onSurface)),
      action: onShow == null
          ? null
          : SnackBarAction(
              label: 'Show',
              textColor: scheme.primary,
              onPressed: onShow,
            ),
    ),
  );
  // SnackBar's internal timer pauses on hover (Material desktop behavior).
  // Force-close after 4s so the snackbar always dismisses when ignored.
  var closed = false;
  controller.closed.then((_) => closed = true);
  Future.delayed(const Duration(seconds: 4), () {
    if (!closed) controller.close();
  });
}
