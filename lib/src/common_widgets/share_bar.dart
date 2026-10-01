import 'package:flutter/material.dart';

/// [share] of a whole, from 0 to 1, as a thin bar in one colour on a track,
/// to compare sizes at a glance: [color], else the theme's primary. Only a
/// picture: the percent is told in text beside it.
class ShareBar extends StatelessWidget {
  final double share;
  final Color? color;

  const ShareBar({super.key, required this.share, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(3);
    return ExcludeSemantics(
      child: Container(
        height: 6,
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: FractionallySizedBox(
          widthFactor: share.clamp(0, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? scheme.primary,
              borderRadius: radius,
            ),
          ),
        ),
      ),
    );
  }
}
