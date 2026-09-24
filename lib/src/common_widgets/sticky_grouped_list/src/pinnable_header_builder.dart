part of '../sticky_grouped_list.dart';

/// Box constraints that also say which group's header to build, so a
/// pinnable header slot can be pointed at a different group during layout.
class _GroupBoxConstraints extends BoxConstraints {
  _GroupBoxConstraints({
    required this.group,
    required BoxConstraints constraints,
  }) : super(
         minWidth: constraints.minWidth,
         maxWidth: constraints.maxWidth,
         minHeight: constraints.minHeight,
         maxHeight: constraints.maxHeight,
       );

  final int? group;

  @override
  bool operator ==(Object other) =>
      other is _GroupBoxConstraints &&
      other.group == group &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.minHeight == minHeight &&
      other.maxHeight == maxHeight;

  @override
  int get hashCode =>
      Object.hash(group, minWidth, maxWidth, minHeight, maxHeight);
}

/// Builds the header of whichever group its constraints name, during layout.
class _PinnableHeaderBuilder
    extends ConstrainedLayoutBuilder<_GroupBoxConstraints> {
  const _PinnableHeaderBuilder({required super.builder});

  @override
  _RenderPinnableHeaderBuilder createRenderObject(BuildContext context) =>
      _RenderPinnableHeaderBuilder();
}

class _RenderPinnableHeaderBuilder extends RenderBox
    with
        RenderObjectWithChildMixin<RenderBox>,
        RenderObjectWithLayoutCallbackMixin,
        RenderAbstractLayoutBuilderMixin<_GroupBoxConstraints, RenderBox> {
  @override
  void performLayout() {
    runLayoutCallback();
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      child?.hitTest(result, position: position) ?? false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset);
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      debugCannotComputeDryLayout(
        reason: 'The header is only built during layout.',
      ),
    );
    return Size.zero;
  }
}
