import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Marks an emoji that matched a search: a tinted, outlined backdrop around
/// the marked part of [child] (all of it, less [inset]).
///
/// The outline sits far enough outside the marked area that its rounded
/// corners clear even a square emoji, so it never covers the emoji. It may
/// reach above and below [child] into the line spacing, so lines keep their
/// height, and adds room at the ends of a run so it doesn't cover neighbours.
///
/// A run of adjacent matches reads as one highlight: [joinsPrevious] and
/// [joinsNext] drop the rounded end and side line where the run continues.
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
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return _RenderSearchMatchMarker(
      fill: colorScheme.primaryContainer,
      outline: colorScheme.primary,
      inset: inset,
      joinsLeft: rtl ? joinsNext : joinsPrevious,
      joinsRight: rtl ? joinsPrevious : joinsNext,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final colorScheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    (renderObject as _RenderSearchMatchMarker)
      ..fill = colorScheme.primaryContainer
      ..outline = colorScheme.primary
      ..inset = inset
      ..joinsLeft = rtl ? joinsNext : joinsPrevious
      ..joinsRight = rtl ? joinsPrevious : joinsNext;
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
    required bool joinsLeft,
    required bool joinsRight,
  }) : _fill = fill,
       _outline = outline,
       _inset = inset,
       _joinsLeft = joinsLeft,
       _joinsRight = joinsRight,
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

  bool _joinsLeft;
  set joinsLeft(bool value) {
    if (value == _joinsLeft) return;
    _joinsLeft = value;
    markNeedsLayout();
  }

  bool _joinsRight;
  set joinsRight(bool value) {
    if (value == _joinsRight) return;
    _joinsRight = value;
    markNeedsLayout();
  }

  /// How far the outline's outer edge sits outside a marked area this tall.
  /// With radius r = (height + 2 * spread) / 4, the outline's inner edge
  /// clears a square corner when spread - stroke >= (r - stroke) * cut.
  static double _spread(double markedHeight) =>
      (_strokeWidth * (1 - _cornerCut) + _cornerCut * markedHeight / 4) /
      (1 - _cornerCut / 2);

  /// Room beside [childSize] for the outline, at the ends of a run.
  (double, double) _sidePadding(Size childSize) {
    final spread = _spread(childSize.height - _inset.vertical);
    return (
      _joinsLeft ? 0.0 : math.max(0.0, spread - _inset.left),
      _joinsRight ? 0.0 : math.max(0.0, spread - _inset.right),
    );
  }

  Size _sizeFor(Size childSize, BoxConstraints constraints) {
    final (left, right) = _sidePadding(childSize);
    return constraints.constrain(
      Size(childSize.width + left + right, childSize.height),
    );
  }

  double _intrinsicWidth(double childWidth) {
    final childHeight = child!.getMinIntrinsicHeight(double.infinity);
    final (left, right) = _sidePadding(Size(childWidth, childHeight));
    return childWidth + left + right;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      child == null ? 0 : _intrinsicWidth(child!.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child == null ? 0 : _intrinsicWidth(child!.getMaxIntrinsicWidth(height));

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
  ) => child?.getDryBaseline(constraints.loosen(), baseline);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    final (left, _) = _sidePadding(child.size);
    (child.parentData! as BoxParentData).offset = Offset(left, 0);
    size = _sizeFor(child.size, constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final childOffset = offset + (child.parentData! as BoxParentData).offset;
    final marked = _inset.deflateRect(childOffset & child.size);
    final box = marked.inflate(_spread(marked.height));
    final radius = box.height / 4;

    // A joined side runs past this emoji's edge and is clipped there, so the
    // rounding and side line only appear at the ends of a run.
    final bounds = offset & size;
    final clip = Rect.fromLTRB(
      _joinsLeft ? bounds.left : box.left,
      box.top,
      _joinsRight ? bounds.right : box.right,
      box.bottom,
    );
    final overhang = radius + _strokeWidth;
    RRect shape(double strokeInset) => RRect.fromRectAndRadius(
      Rect.fromLTRB(
        _joinsLeft ? box.left - overhang : box.left + strokeInset,
        box.top + strokeInset,
        _joinsRight ? box.right + overhang : box.right - strokeInset,
        box.bottom - strokeInset,
      ),
      Radius.circular(radius),
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
