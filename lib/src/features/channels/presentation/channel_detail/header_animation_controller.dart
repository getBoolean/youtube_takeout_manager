import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, `VideoGroupHeader` should render size transitions instantly
/// instead of spring-animating them. Used during the scroll-to-target flow
/// so that layout-extent shifts caused by headers pinning/compacting happen
/// in a single frame — letting the scroll controller converge on the
/// correct offset without chasing a moving layout.
class SuppressHeaderAnimation extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool active}) => state = active;
}

final suppressHeaderAnimationProvider =
    NotifierProvider<SuppressHeaderAnimation, bool>(
      SuppressHeaderAnimation.new,
    );
