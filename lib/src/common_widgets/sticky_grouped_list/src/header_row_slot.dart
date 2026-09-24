part of '../sticky_grouped_list.dart';

/// Wraps a header row in the list. While the group's pinned copy is shown,
/// the row keeps its size (so the list doesn't shift) but paints nothing and
/// ignores hits.
class _HeaderRowSlot extends SingleChildRenderObjectWidget {
  const _HeaderRowSlot({
    super.key,
    required this.group,
    required this.facts,
    required super.child,
  });

  final int group;
  final _LayoutFacts facts;

  @override
  _RenderHeaderRowSlot createRenderObject(BuildContext context) =>
      _RenderHeaderRowSlot(group, facts);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeaderRowSlot renderObject,
  ) {
    renderObject
      ..group = group
      ..facts = facts;
  }
}

class _RenderHeaderRowSlot extends RenderProxyBox {
  _RenderHeaderRowSlot(this._group, this._facts);

  int _group;
  set group(int value) {
    if (_group == value) return;
    _group = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  _LayoutFacts _facts;
  set facts(_LayoutFacts value) {
    if (identical(_facts, value)) return;
    if (attached) _facts.headerRowSlots.remove(this);
    _facts = value;
    if (attached) _facts.headerRowSlots.add(this);
    markNeedsPaint();
  }

  bool get _hidden => _facts.hiddenHeaderGroup == _group;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _facts.headerRowSlots.add(this);
  }

  @override
  void detach() {
    _facts.headerRowSlots.remove(this);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hidden) super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      !_hidden && super.hitTest(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_hidden) super.visitChildrenForSemantics(visitor);
  }
}
