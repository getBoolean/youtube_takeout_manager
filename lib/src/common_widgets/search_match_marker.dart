import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Marks an emoji that matched a search: a tinted, outlined backdrop around
/// the marked part of [child] (all of it, less [inset]).
///
/// The outline sits far enough outside the marked area that its rounded
/// corners clear even a square emoji, so it never covers the emoji. The
/// marker makes room for it, so it doesn't cover neighbours or other lines.
///
/// A run of adjacent matches reads as one highlight: [joinsPrevious] and
/// [joinsNext] drop the rounded end and side line where the run continues on
/// the same line, and space the emojis like the outline.
class SearchMatchMarker extends SingleChildRenderObjectWidget {
  /// The part of [child] not to mark, e.g. the space a text line reserves
  /// around its glyphs.
  final EdgeInsets inset;
  final bool joinsPrevious;
  final bool joinsNext;

  const SearchMatchMarker({
    super.key,
    required Widget super.child,
    this.inset = EdgeInsets.zero,
    this.joinsPrevious = false,
    this.joinsNext = false,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _RenderSearchMatchMarker(
      fill: colorScheme.primaryContainer,
      outline: colorScheme.primary,
      inset: inset,
      joinsPrevious: joinsPrevious,
      joinsNext: joinsNext,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final colorScheme = Theme.of(context).colorScheme;
    (renderObject as _RenderSearchMatchMarker)
      ..fill = colorScheme.primaryContainer
      ..outline = colorScheme.primary
      ..inset = inset
      ..joinsPrevious = joinsPrevious
      ..joinsNext = joinsNext
      ..textDirection = Directionality.of(context);
  }
}

class _RenderSearchMatchMarker extends RenderShiftedBox {
  static const _strokeWidth = 1.5;

  /// How far a rounded corner cuts in along the diagonal, per unit radius.
  static const _cornerCut = 1 - 1 / math.sqrt2;

  _RenderSearchMatchMarker({
    required Color fill,
    required Color outline,
    required EdgeInsets inset,
    required bool joinsPrevious,
    required bool joinsNext,
    required TextDirection textDirection,
  }) : _fill = fill,
       _outline = outline,
       _inset = inset,
       _joinsPrevious = joinsPrevious,
       _joinsNext = joinsNext,
       _textDirection = textDirection,
       super(null);

  Color _fill;
  set fill(Color value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsPaint();
  }

  Color _outline;
  set outline(Color value) {
    if (value == _outline) return;
    _outline = value;
    markNeedsPaint();
  }

  EdgeInsets _inset;
  set inset(EdgeInsets value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsLayout();
  }

  bool _joinsPrevious;
  set joinsPrevious(bool value) {
    if (value == _joinsPrevious) return;
    _joinsPrevious = value;
    markNeedsLayout();
  }

  bool _joinsNext;
  set joinsNext(bool value) {
    if (value == _joinsNext) return;
    _joinsNext = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool get _rtl => _textDirection == TextDirection.rtl;
  bool get _joinsLeft => _rtl ? _joinsNext : _joinsPrevious;
  bool get _joinsRight => _rtl ? _joinsPrevious : _joinsNext;

  /// How far the outline's outer edge sits outside a marked area this tall.
  /// With radius r = (height + 2 * spread) / 4, the outline's inner edge
  /// clears a square corner when spread - stroke >= (r - stroke) * cut.
  static double _spread(double markedHeight) =>
      (_strokeWidth * (1 - _cornerCut) + _cornerCut * markedHeight / 4) /
      (1 - _cornerCut / 2);

  /// Room around a child of [childSize] for the outline, plus half the gap
  /// between an emoji and its outline: emojis in a run, and a marker and
  /// whatever is next to it (another line's marker, say), are that far
  /// apart.
  EdgeInsets _padding(Size childSize) {
    final spread = _spread(childSize.height - _inset.vertical);
    final halfGap = (spread - _strokeWidth) / 2;
    double side(double inset, {required bool joined}) =>
        math.max(0.0, (joined ? halfGap : spread + halfGap) - inset);
    return EdgeInsets.fromLTRB(
      side(_inset.left, joined: _joinsLeft),
      side(_inset.top, joined: false),
      side(_inset.right, joined: _joinsRight),
      side(_inset.bottom, joined: false),
    );
  }

  Size _sizeFor(Size childSize, BoxConstraints constraints) =>
      constraints.constrain(_padding(childSize).inflateSize(childSize));

  @override
  double computeMinIntrinsicWidth(double height) {
    final child = this.child;
    if (child == null) return 0;
    final childSize = Size(
      child.getMinIntrinsicWidth(height),
      child.getMinIntrinsicHeight(double.infinity),
    );
    return _padding(childSize).inflateSize(childSize).width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final child = this.child;
    if (child == null) return 0;
    final childSize = Size(
      child.getMaxIntrinsicWidth(height),
      child.getMinIntrinsicHeight(double.infinity),
    );
    return _padding(childSize).inflateSize(childSize).width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final child = this.child;
    if (child == null) return 0;
    final height = child.getMinIntrinsicHeight(width);
    return height + _padding(Size(width, height)).vertical;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final child = this.child;
    if (child == null) return 0;
    final height = child.getMaxIntrinsicHeight(width);
    return height + _padding(Size(width, height)).vertical;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _sizeFor(child.getDryLayout(constraints.loosen()), constraints);
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final childConstraints = constraints.loosen();
    final childBaseline = child.getDryBaseline(childConstraints, baseline);
    if (childBaseline == null) return null;
    return childBaseline + _padding(child.getDryLayout(childConstraints)).top;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = _padding(child.size).topLeft;
    size = _sizeFor(child.size, constraints);
  }

  /// Whether the emoji beside this one on [left] (in a run) is on the same
  /// line. A run can wrap: then each line's part gets its own rounded end.
  bool _neighbourOnSameLine({required bool left}) {
    RenderObject? inline = this;
    while (inline != null && inline.parent is! RenderParagraph) {
      inline = inline.parent;
    }
    if (inline is! RenderBox) return true;
    final data = inline.parentData! as TextParentData;
    final neighbour = left == _rtl ? data.nextSibling : data.previousSibling;
    final mine = data.offset;
    final theirs = (neighbour?.parentData as TextParentData?)?.offset;
    if (neighbour == null || mine == null || theirs == null) return false;
    // Boxes on consecutive lines can touch; ones on the same line mostly
    // coincide.
    final myBox = mine & inline.size;
    final theirBox = theirs & neighbour.size;
    final shared =
        math.min(myBox.bottom, theirBox.bottom) -
        math.max(myBox.top, theirBox.top);
    return shared > math.min(myBox.height, theirBox.height) / 2;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final childOffset = offset + (child.parentData! as BoxParentData).offset;
    final marked = _inset.deflateRect(childOffset & child.size);
    final spread = _spread(marked.height);
    final joinsLeft = _joinsLeft && _neighbourOnSameLine(left: true);
    final joinsRight = _joinsRight && _neighbourOnSameLine(left: false);

    // A joined side stops at this emoji's edge, where the neighbour's part
    // of the run continues.
    final bounds = offset & size;
    final box = Rect.fromLTRB(
      joinsLeft ? bounds.left : marked.left - spread,
      marked.top - spread,
      joinsRight ? bounds.right : marked.right + spread,
      marked.bottom + spread,
    );
    final radius = box.height / 4;
    // The shape runs past a joined side and is clipped there, so the rounding
    // and side line only appear at the ends of a run.
    final overhang = radius + _strokeWidth;
    RRect shape(double strokeInset) => RRect.fromRectAndRadius(
      Rect.fromLTRB(
        joinsLeft ? box.left - overhang : box.left + strokeInset,
        box.top + strokeInset,
        joinsRight ? box.right + overhang : box.right - strokeInset,
        box.bottom - strokeInset,
      ),
      Radius.circular(radius),
    );
    // Overlap the neighbour's half of the gap so the two parts leave no
    // anti-aliased seam; it's clear of both emojis and painted alike.
    final joinOverlap = (spread - _strokeWidth) / 2;
    final clip = Rect.fromLTRB(
      joinsLeft ? box.left - joinOverlap : box.left,
      box.top,
      joinsRight ? box.right + joinOverlap : box.right,
      box.bottom,
    );

    context.canvas
      ..save()
      ..clipRect(clip)
      ..drawRRect(shape(0), Paint()..color = _fill)
      ..restore();
    context.paintChild(child, childOffset);
    context.canvas
      ..save()
      ..clipRect(clip)
      ..drawRRect(
        shape(_strokeWidth / 2),
        Paint()
          ..color = _outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      )
      ..restore();
  }
}

/// Emojis that matched a search, drawn exactly like the surrounding text with
/// a [SearchMatchMarker] fitted to the emoji glyphs.
///
/// A text line reserves more height than emoji glyphs fill, by an amount that
/// depends on the fonts, and no text API reports where glyphs draw. So the
/// first time a style is used, a reference emoji is drawn offscreen in it and
/// its pixels measured. Until then the emojis show unmarked.
class SearchMatchedEmojis extends StatefulWidget {
  final String emojis;
  final TextStyle style;

  const SearchMatchedEmojis({
    super.key,
    required this.emojis,
    required this.style,
  });

  @override
  State<SearchMatchedEmojis> createState() => _SearchMatchedEmojisState();
}

class _SearchMatchedEmojisState extends State<SearchMatchedEmojis> {
  /// Measured insets (null if nothing drew), keyed by style and pixel ratio.
  static final _measured = <(TextStyle, double), EdgeInsets?>{};
  static final _measuring = <(TextStyle, double), Future<EdgeInsets?>>{};

  EdgeInsets? _inset;
  (TextStyle, double)? _key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(SearchMatchedEmojis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) _update();
  }

  void _update() {
    final key = (widget.style, View.of(context).devicePixelRatio);
    if (key == _key) return;
    _key = key;
    if (_measured.containsKey(key)) {
      _inset = _measured[key] ?? EdgeInsets.zero;
      return;
    }
    _inset = null;
    _measuring
        .putIfAbsent(
          key,
          // Unmeasurable: mark the whole line box instead.
          () => _measureGlyphInset(key.$1, key.$2).catchError((_) => null),
        )
        .then((inset) {
          _measured[key] = inset;
          _measuring.remove(key);
          if (mounted && _key == key) {
            setState(() => _inset = inset ?? EdgeInsets.zero);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.emojis,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
      // The enclosing text already scales its widget spans.
      textScaler: TextScaler.noScaling,
    );
    final inset = _inset;
    if (inset == null) return text;
    return SearchMatchMarker(inset: inset, child: text);
  }
}

/// Where a reference emoji draws within its box in a line of [style]: the
/// space around its pixels. Emoji fonts draw every emoji in the same square,
/// so this fits any run of them. Null if it drew nothing.
Future<EdgeInsets?> _measureGlyphInset(
  TextStyle style,
  double pixelRatio,
) async {
  final painter = TextPainter(
    text: TextSpan(text: '\u{1F600}', style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
  )..layout();
  final advance = painter.width;
  final lineHeight = painter.height;
  final width = (advance * pixelRatio).ceil();
  final height = (lineHeight * pixelRatio).ceil();
  if (width == 0 || height == 0) {
    painter.dispose();
    return null;
  }

  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder)..scale(pixelRatio), Offset.zero);
  painter.dispose();
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final pixels = await image.toByteData();
  image.dispose();
  if (pixels == null) return null;

  int? top, bottom, left, right;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (pixels.getUint8((y * width + x) * 4 + 3) == 0) continue;
      top ??= y;
      bottom = y + 1;
      if (left == null || x < left) left = x;
      if (right == null || x + 1 > right) right = x + 1;
    }
  }
  if (top == null) return null;
  return EdgeInsets.fromLTRB(
    left! / pixelRatio,
    top / pixelRatio,
    advance - right! / pixelRatio,
    lineHeight - bottom! / pixelRatio,
  );
}
