import 'package:flutter/widgets.dart';

/// Below this width, labeled buttons shrink to icons.
const compactWidthBreakpoint = 600.0;

/// At or above this width there's room for a docked side pane.
const expandedWidthBreakpoint = 960.0;

/// Below this width even icons beside labels don't fit, so they're left out.
const tinyWidthBreakpoint = 200.0;

bool isCompactWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < compactWidthBreakpoint;

bool isTinyWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < tinyWidthBreakpoint;

/// Dialog margins for compact widths, narrower than the default 40 so a
/// dialog's content still fits in a tiny window.
const compactDialogInsets = EdgeInsets.symmetric(horizontal: 16, vertical: 24);
