import 'package:flutter/material.dart';

/// Renders text with substrings matching [query] visually emphasized.
///
/// Use [HighlightedText] for plain strings and [HighlightedText.rich] when
/// the source is already a list of [InlineSpan]s (e.g. comment spans with
/// mixed text and emoji [WidgetSpan]s). Matching is case-insensitive.
class HighlightedText extends StatelessWidget {
  final String? text;
  final List<InlineSpan>? spans;
  final String? query;
  final TextStyle? style;
  final TextStyle? matchStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedText(
    String this.text, {
    super.key,
    this.query,
    this.style,
    this.matchStyle,
    this.maxLines,
    this.overflow,
  }) : spans = null;

  const HighlightedText.rich(
    List<InlineSpan> this.spans, {
    super.key,
    this.query,
    this.style,
    this.matchStyle,
    this.maxLines,
    this.overflow,
  }) : text = null;

  @override
  Widget build(BuildContext context) {
    final q = query ?? '';
    final effectiveMatch =
        matchStyle ??
        TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        );

    final List<InlineSpan> children;
    if (spans != null) {
      children = q.isEmpty
          ? spans!
          : spans!
                .expand((s) => _highlightSpan(s, q, effectiveMatch))
                .toList(growable: false);
    } else {
      children = _highlightString(text!, q, effectiveMatch);
    }

    return Text.rich(
      TextSpan(children: children),
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

List<InlineSpan> _highlightString(String text, String query, TextStyle match) {
  if (query.isEmpty || text.isEmpty) return [TextSpan(text: text)];
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final hit = lower.indexOf(q, i);
    if (hit < 0) {
      spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    if (hit > i) spans.add(TextSpan(text: text.substring(i, hit)));
    spans.add(TextSpan(text: text.substring(hit, hit + q.length), style: match));
    i = hit + q.length;
  }
  return spans;
}

Iterable<InlineSpan> _highlightSpan(
  InlineSpan span,
  String query,
  TextStyle match,
) {
  if (span is TextSpan) {
    final text = span.text;
    if (text == null || text.isEmpty) return [span];
    return _highlightString(text, query, match).map((sub) {
      if (sub is TextSpan && sub.style == match) {
        return TextSpan(
          text: sub.text,
          style: (span.style ?? const TextStyle()).merge(match),
        );
      }
      return TextSpan(text: (sub as TextSpan).text, style: span.style);
    });
  }
  return [span];
}
