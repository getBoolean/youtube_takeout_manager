import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

/// Premium motion preset used across animated widgets in the app.
///
/// Honors the OS "reduced motion" setting: when [MediaQuery.disableAnimations]
/// is true, falls back to [CueMotion.none] so users who opt out of animation
/// see instant state changes.
CueMotion premiumSpring(BuildContext context) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
    return CueMotion.none;
  }
  return const Spring.smooth();
}

/// A [Text] that slides+fades the new value down from the top each time [count]
/// changes. Used for badge counts, chip counts, and tab counts so numeric
/// updates feel like a morph rather than a hard swap.
class AnimatedCountText extends StatelessWidget {
  final int count;
  final TextStyle? style;
  final TextAlign? textAlign;

  const AnimatedCountText(this.count, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Cue.onChange(
      value: count,
      motion: premiumSpring(context),
      acts: const [OpacityAct.fadeIn(), SlideAct.y(from: -0.4)],
      child: Text(
        '$count',
        key: ValueKey(count),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// Wraps a [child] so it animates out of the tree (clip + fade + slide) when
/// [visible] is false, keeping the widget present so enter/exit both animate.
///
/// Intended for widgets handed to `Scaffold.bottomNavigationBar` or similar
/// slots where conditional rendering would otherwise cause a hard pop.
class AnimatedBottomBar extends StatelessWidget {
  final bool visible;
  final Widget child;

  const AnimatedBottomBar({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final motion = premiumSpring(context);
    return Cue.onToggle(
      toggled: visible,
      motion: motion,
      reverseMotion: motion,
      acts: const [
        ClipAct.height(fromFactor: 0.0, toFactor: 1.0),
        OpacityAct.fadeIn(),
        SlideAct.y(from: 1.0),
      ],
      child: child,
    );
  }
}
