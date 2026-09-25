import 'package:flutter/widgets.dart';

/// Below this width, labeled buttons shrink to icons.
const compactWidthBreakpoint = 600.0;

/// At or above this width there's room for a docked side pane.
const expandedWidthBreakpoint = 960.0;

bool isCompactWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < compactWidthBreakpoint;
