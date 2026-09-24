import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'header_animation_controller.dart';
import 'video_group_header.dart';

/// Scrolls [scrollController] so the widget at [tileContext] lands just below
/// the sticky [VideoGroupHeader] instead of being hidden behind it.
///
/// The target group is built with [VideoGroupHeader.forceCompact] and its
/// siblings are pre-collapsed, so every header is already at its compact
/// height from the first frame — the panel's scroll extent can't shrink
/// during the animation. That makes a single `animateTo` land on exactly
/// the right offset without any follow-up correction. The offset is the
/// target header's measured height plus a 12px gap, so tiles stay visible
/// below the pinned header even when the title wraps to two lines.
Future<void> scrollTileBelowHeader(
  BuildContext? tileContext,
  GlobalKey? headerKey,
  ScrollController scrollController,
  SuppressHeaderAnimation suppressHeaderAnimation,
) async {
  if (tileContext == null || !tileContext.mounted) return;
  if (!scrollController.hasClients) return;
  final tileBox = tileContext.findRenderObject();
  if (tileBox is! RenderBox || !tileBox.hasSize) return;

  const gap = 12.0;
  final headerBox = headerKey?.currentContext?.findRenderObject();
  final headerHeight = (headerBox is RenderBox && headerBox.hasSize)
      ? headerBox.size.height
      : 104.0;
  final targetPixelOffset = headerHeight + gap;

  suppressHeaderAnimation.set(active: true);
  try {
    final revealOffset = RenderAbstractViewport.of(
      tileBox,
    ).getOffsetToReveal(tileBox, 0.0).offset;
    final position = scrollController.position;
    final target = (revealOffset - targetPixelOffset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - scrollController.offset).abs() < 0.5) return;
    await scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  } finally {
    suppressHeaderAnimation.set(active: false);
  }
}
