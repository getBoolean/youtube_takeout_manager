/// A lazily built, vertically scrolling list of collapsible groups whose
/// headers pin to the top of the viewport and are pushed up by the next
/// group's header.
///
/// Only rows within the viewport and its cache extent are built, however many
/// groups and items there are. Each group's header may own a piece of state
/// (`S`, e.g. an animation controller) created and updated through callbacks;
/// the in-list header and its pinned copy share it, so pinning never restarts
/// a header animation. Header statuses are computed during layout and pushed
/// through `updateHeaderState` on the same frame the scroll position changes.
///
/// Self-contained: depends on nothing but Flutter.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'src/group_rows.dart';

part 'src/header_row_slot.dart';
part 'src/layout_facts.dart';
part 'src/lazy_sliver_list.dart';
part 'src/pinnable_header_builder.dart';
part 'src/render_sticky_grouped_sliver.dart';
part 'src/sticky_grouped_list_controller.dart';
part 'src/sticky_grouped_list_view.dart';
part 'src/sticky_header_status.dart';
