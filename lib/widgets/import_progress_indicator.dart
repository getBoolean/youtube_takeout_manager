import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import 'cue_motion.dart';

class ImportProgressIndicator extends StatelessWidget {
  final String message;

  const ImportProgressIndicator({
    super.key,
    this.message = 'Importing takeout data...',
  });

  @override
  Widget build(BuildContext context) {
    return Cue.onMount(
      motion: premiumSpring(context),
      acts: const [OpacityAct.fadeIn(), ScaleAct(from: 0.92)],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Cue.onChange(
            value: message,
            motion: premiumSpring(context),
            acts: const [OpacityAct.fadeIn(), SlideAct.y(from: 0.2)],
            child: Text(
              message,
              key: ValueKey(message),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
