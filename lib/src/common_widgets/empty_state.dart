import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import 'cue_motion.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Cue.onMount(
        motion: premiumSpring(context),
        acts: const [
          OpacityAct.fadeIn(),
          SlideAct.y(from: 0.15),
          ScaleAct(from: 0.95),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
