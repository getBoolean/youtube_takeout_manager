import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/routing/app_router.dart';

/// Opens the takeout's watch and search history. Disabled while there's
/// nothing to open, e.g. while the takeout loads.
class HistoryButton extends StatelessWidget {
  final bool enabled;

  const HistoryButton({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      tooltip: 'Watch and search history',
      onPressed: enabled
          ? () => context.router.push(const HistoryRoute())
          : null,
    );
  }
}
