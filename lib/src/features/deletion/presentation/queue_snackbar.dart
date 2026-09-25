import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'queue_panel/deletion_queue_layout.dart';

void showQueuedForDeletionSnackBar(
  BuildContext context,
  WidgetRef ref, {
  required String message,
}) {
  final scheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  final showQueue = deletionQueueOpener(context, ref);
  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      backgroundColor: scheme.surfaceContainerHigh,
      content: Text(message, style: TextStyle(color: scheme.onSurface)),
      action: showQueue == null
          ? null
          : SnackBarAction(
              label: 'Show',
              textColor: scheme.primary,
              onPressed: showQueue,
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
