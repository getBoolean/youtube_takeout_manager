import 'package:flutter/material.dart';

/// Wraps [child] and — when [active] is true — plays a one-shot pulse that
/// fades a [ColorScheme.primaryContainer] background in then out behind it,
/// drawing attention to an item that was just scrolled into view.
///
/// Calls [onComplete] once after the animation finishes so the caller can
/// clear whatever flag is keeping `active` true, making this effectively a
/// single-play highlight.
class ScrollTargetHighlight extends StatelessWidget {
  final bool active;
  final Widget child;
  final VoidCallback? onComplete;
  final Duration duration;

  const ScrollTargetHighlight({
    super.key,
    required this.active,
    required this.child,
    this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeInOut,
      onEnd: onComplete,
      builder: (context, t, child) {
        // Up-then-down curve: peaks near t=0.5, fades back to 0 at t=1.
        final intensity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
        return ColoredBox(
          color: colorScheme.primaryContainer.withValues(alpha: intensity),
          child: child,
        );
      },
      child: child,
    );
  }
}
