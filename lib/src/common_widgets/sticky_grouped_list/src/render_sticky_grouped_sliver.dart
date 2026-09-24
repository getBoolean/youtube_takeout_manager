part of '../sticky_grouped_list.dart';

/// Receives the list's layout from [_RenderStickyGroupedSliver].
abstract interface class _StickyLayoutHost {
  _LayoutFacts get facts;

  int get groupCount;

  /// Called during layout with the current heights of the headers around
  /// the last pinned group, before the rows are laid out. Returns how far to
  /// move the laid-out rows for headers above them that resized while their
  /// rows weren't laid out.
  double shiftForResizedHeaders(Map<int, double> headerHeights);

  /// Called during layout after the rows are laid out. Runs inside a layout
  /// callback, so it may update state that dirties this sliver's descendants.
  void onRowsLaidOut(RenderSliverMultiBoxAdaptor list, double pixels);

  /// Re-reads the rows after they were laid out again, without updating
  /// header states.
  void onRowsRelaidOut(RenderSliverMultiBoxAdaptor list, double pixels);

  /// The groups whose headers the pinnable slots now hold.
  void onPinnableGroups(Iterable<int> groups);
}

enum _Slot { list, header0, header1, header2 }

const _headerSlots = [_Slot.header0, _Slot.header1, _Slot.header2];

/// The pinned group and its neighbours, each in the slot `group % 3` so a
/// group keeps its slot (and element) as the pinned group moves by one.
Map<_Slot, int?> _slotGroupsAround(int anchor, int groupCount) {
  final slots = <_Slot, int?>{for (final slot in _headerSlots) slot: null};
  for (var g = anchor - 1; g <= anchor + 1; g++) {
    if (g >= 0 && g < groupCount) slots[_headerSlots[g % 3]] = g;
  }
  return slots;
}

/// The row list plus the headers around the pinned group, built during
/// layout; the pinned group's is painted over the rows.
class _StickyGroupedSliver
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderObject> {
  const _StickyGroupedSliver({
    required this.host,
    required this.list,
    required this.pinnableHeaderBuilder,
  });

  final _StickyLayoutHost host;
  final Widget list;
  final Widget Function(BuildContext context, int group) pinnableHeaderBuilder;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.list => list,
    _ => _PinnableHeaderBuilder(
      builder: (context, constraints) => switch (constraints.group) {
        final group? => pinnableHeaderBuilder(context, group),
        null => const SizedBox.shrink(),
      },
    ),
  };

  @override
  _RenderStickyGroupedSliver createRenderObject(BuildContext context) =>
      _RenderStickyGroupedSliver(host: host);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderStickyGroupedSliver renderObject,
  ) {
    renderObject.host = host;
  }
}

class _RenderStickyGroupedSliver extends RenderSliver
    with
        SlottedContainerRenderObjectMixin<_Slot, RenderObject>,
        RenderSliverHelpers {
  _RenderStickyGroupedSliver({required _StickyLayoutHost host}) : _host = host;

  _StickyLayoutHost _host;
  set host(_StickyLayoutHost value) {
    if (identical(_host, value)) return;
    _host = value;
    markNeedsLayout();
  }

  _Slot? _pinnedSlot;
  double _pinnedOffset = 0;

  RenderSliverMultiBoxAdaptor get _list =>
      childForSlot(_Slot.list)! as RenderSliverMultiBoxAdaptor;

  RenderBox _header(_Slot slot) => childForSlot(slot)! as RenderBox;

  RenderBox? get _pinnedHeader {
    final slot = _pinnedSlot;
    return slot == null ? null : _header(slot);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  Map<_Slot, int?> _layOutHeaders(int anchor) {
    final slotGroups = _slotGroupsAround(anchor, _host.groupCount);
    final boxConstraints = constraints.asBoxConstraints();
    for (final slot in _headerSlots) {
      _header(slot).layout(
        _GroupBoxConstraints(
          group: slotGroups[slot],
          constraints: boxConstraints,
        ),
        parentUsesSize: true,
      );
    }
    return slotGroups;
  }

  @override
  void performLayout() {
    assert(
      constraints.axisDirection == AxisDirection.down,
      'StickyGroupedListView only supports vertical, top-down scrolling.',
    );
    final facts = _host.facts;
    final list = _list;

    // Headers above the laid-out rows keep animating through these copies;
    // move the rows by any change in their height, as the space above them
    // changed.
    final before = _layOutHeaders(facts.pinnedGroup ?? facts.topGroup ?? 0);
    final heights = <int, double>{
      for (final MapEntry(key: slot, value: group) in before.entries)
        ?group: _header(slot).size.height,
    };
    invokeLayoutCallback<SliverConstraints>((_) {
      final shift = _host.shiftForResizedHeaders(heights);
      if (shift == 0) return;
      for (var row = list.firstChild; row != null; row = list.childAfter(row)) {
        final parentData = row.parentData! as SliverMultiBoxAdaptorParentData;
        parentData.layoutOffset = parentData.layoutOffset! + shift;
      }
      list.markNeedsLayout();
    });

    list.layout(constraints, parentUsesSize: true);
    if (list.geometry!.scrollOffsetCorrection != null) {
      geometry = list.geometry;
      return;
    }
    invokeLayoutCallback<SliverConstraints>((constraints) {
      _host.onRowsLaidOut(list, constraints.scrollOffset);
    });

    // Header state updates may have resized rows; lay them out again (a
    // no-op when nothing changed).
    list.layout(constraints, parentUsesSize: true);
    final listGeometry = list.geometry!;
    if (listGeometry.scrollOffsetCorrection != null) {
      geometry = listGeometry;
      return;
    }
    invokeLayoutCallback<SliverConstraints>((constraints) {
      _host.onRowsRelaidOut(list, constraints.scrollOffset);
    });

    final after = _layOutHeaders(facts.pinnedGroup ?? facts.topGroup ?? 0);
    _host.onPinnableGroups(after.values.nonNulls);
    final previousPinnedSlot = _pinnedSlot;
    _pinnedSlot = null;
    for (final MapEntry(key: slot, value: group) in after.entries) {
      if (group != null && group == facts.pinnedGroup) _pinnedSlot = slot;
    }
    if (_pinnedSlot != previousPinnedSlot) markNeedsSemanticsUpdate();

    final pinned = _pinnedHeader;
    _pinnedOffset = pinned == null
        ? 0
        : math.min(
            0,
            facts.topGroupEnd - constraints.scrollOffset - pinned.size.height,
          );

    final hidden = pinned == null ? null : facts.pinnedGroup;
    if (hidden != facts.hiddenHeaderGroup) {
      facts.hiddenHeaderGroup = hidden;
      for (final slot in facts.headerRowSlots) {
        slot
          ..markNeedsPaint()
          ..markNeedsSemanticsUpdate();
      }
    }

    geometry = listGeometry;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!geometry!.visible) return;
    context.paintChild(_list, offset);
    final pinned = _pinnedHeader;
    if (pinned != null) {
      context.paintChild(pinned, offset + Offset(0, _pinnedOffset));
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    final pinned = _pinnedHeader;
    if (pinned != null &&
        hitTestBoxChild(
          BoxHitTestResult.wrap(result),
          pinned,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        )) {
      return true;
    }
    return _list.hitTest(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }

  @override
  double childMainAxisPosition(RenderObject child) =>
      child is RenderBox ? _pinnedOffset : 0;

  @override
  double childCrossAxisPosition(RenderObject child) => 0;

  @override
  double? childScrollOffset(RenderObject child) =>
      child is RenderBox ? constraints.scrollOffset + _pinnedOffset : 0;

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child is RenderBox) transform.translateByDouble(0, _pinnedOffset, 0, 1);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitor(_list);
    final pinned = _pinnedHeader;
    if (pinned != null) visitor(pinned);
  }
}
