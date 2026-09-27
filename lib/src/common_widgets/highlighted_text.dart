import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import 'search_match_marker.dart';

/// Renders text with substrings matching [query] visually emphasized; matched
/// emojis get a [SearchMatchMarker].
///
/// Use [HighlightedText] for plain strings and [HighlightedText.rich] when
/// the source is already a list of [InlineSpan]s (e.g. comment spans with
/// mixed text and emoji [WidgetSpan]s). Matching is case-insensitive and
/// ignores U+FE0F, like search (see [foldForSearch]).
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

    final highlighter = _Highlighter(
      query: foldForSearch(q),
      match: effectiveMatch,
      baseStyle: DefaultTextStyle.of(context).style.merge(style),
    );

    final List<InlineSpan> children;
    if (spans != null) {
      children = q.isEmpty
          ? spans!
          : _joinTextSpans(
              spans!,
            ).expand(highlighter.span).toList(growable: false);
    } else {
      children = highlighter.string(text!, null);
    }

    return Text.rich(
      TextSpan(children: children),
      style: style,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

class _Highlighter {
  /// Already folded (see [foldForSearch]).
  final String query;
  final TextStyle match;

  /// The style the highlighted text is drawn with, for text moved into a
  /// [WidgetSpan].
  final TextStyle baseStyle;

  const _Highlighter({
    required this.query,
    required this.match,
    required this.baseStyle,
  });

  Iterable<InlineSpan> span(InlineSpan span) {
    if (span is! TextSpan) return [span];
    final text = span.text;
    if (text == null || text.isEmpty) return [span];
    return string(text, span.style);
  }

  /// [text] split into plain and matched spans, drawn with [style].
  List<InlineSpan> string(String text, TextStyle? style) {
    final ranges = _matchRanges(text, query);
    if (ranges.isEmpty) return [TextSpan(text: text, style: style)];
    final spans = <InlineSpan>[];
    var i = 0;
    for (final (start, end) in ranges) {
      if (start > i) {
        spans.add(TextSpan(text: text.substring(i, start), style: style));
      }
      spans.addAll(_matched(text.substring(start, end), style));
      i = end;
    }
    if (i < text.length) {
      spans.add(TextSpan(text: text.substring(i), style: style));
    }
    return spans;
  }

  /// A match, split into runs of emojis and of other text.
  Iterable<InlineSpan> _matched(String text, TextStyle? style) sync* {
    final run = StringBuffer();
    bool? emojiRun;
    for (final char in text.characters) {
      final emoji = _isEmoji(char);
      if (emojiRun != null && emoji != emojiRun) {
        yield _run('$run', emoji: emojiRun, style: style);
        run.clear();
      }
      emojiRun = emoji;
      run.write(char);
    }
    if (emojiRun != null) yield _run('$run', emoji: emojiRun, style: style);
  }

  /// Text gets [match]. Emojis get a [SearchMatchMarker] like matched
  /// channel emojis, since color glyphs ignore text color and weight.
  InlineSpan _run(String text, {required bool emoji, TextStyle? style}) {
    if (!emoji) {
      return TextSpan(
        text: text,
        style: (style ?? const TextStyle()).merge(match),
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: SearchMatchedEmojis(emojis: text, style: baseStyle.merge(style)),
    );
  }
}

/// Whether [char] (one user-perceived character) is an emoji rather than
/// text. Approximate: emoji selectors, ZWJ sequences and keycaps, plus the
/// pictographic blocks.
bool _isEmoji(String char) {
  for (final rune in char.runes) {
    if (rune == 0xFE0F || rune == 0x200D || rune == 0x20E3) return true;
    if (rune >= 0x1F000 && rune <= 0x1FAFF) return true; // 😀 🔥 🇺🇸
    if (rune >= 0x2600 && rune <= 0x27BF) return true; // ☀ ❤ ✨ ✅
    if (rune >= 0x2300 && rune <= 0x23FF) return true; // ⌚ ⏰
    if (rune >= 0x2B00 && rune <= 0x2BFF) return true; // ⭐ ⬛
  }
  return false;
}

/// Joins neighbouring plain [TextSpan]s with the same style, so a match that
/// spans them (e.g. a run of emojis split across comment segments) is
/// highlighted as one.
List<InlineSpan> _joinTextSpans(List<InlineSpan> spans) {
  bool plain(InlineSpan span) =>
      span is TextSpan &&
      span.text != null &&
      span.children == null &&
      span.recognizer == null;
  final result = <InlineSpan>[];
  for (final span in spans) {
    final last = result.lastOrNull;
    if (last is TextSpan &&
        plain(last) &&
        plain(span) &&
        last.style == span.style) {
      result.last = TextSpan(
        text: last.text! + (span as TextSpan).text!,
        style: span.style,
      );
    } else {
      result.add(span);
    }
  }
  return result;
}

/// Ranges of [text] that match [folded] (see [foldForSearch]), widened to
/// whole characters so an emoji's skin tone, U+FE0F or ZWJ sequence isn't
/// split across differently styled spans.
List<(int, int)> _matchRanges(String text, String folded) {
  if (folded.isEmpty || text.isEmpty) return const [];

  // The folded text, plus the offset in [text] of each of its code units
  // (null while nothing was removed).
  final List<int>? offsets;
  final String haystack;
  if (text.contains('\u{FE0F}')) {
    offsets = [
      for (var i = 0; i < text.length; i++)
        if (text.codeUnitAt(i) != 0xFE0F) i,
    ];
    haystack = String.fromCharCodes(offsets.map(text.codeUnitAt)).toLowerCase();
    if (haystack.length != offsets.length) return const [];
  } else {
    offsets = null;
    haystack = text.toLowerCase();
    // Lowercasing changed the length (e.g. 'İ'); offsets wouldn't line up.
    if (haystack.length != text.length) return const [];
  }

  final ranges = <(int, int)>[];
  var from = 0;
  while (true) {
    final hit = haystack.indexOf(folded, from);
    if (hit < 0) break;
    from = hit + folded.length;
    final last = hit + folded.length - 1;
    final chars = CharacterRange.at(
      text,
      offsets?[hit] ?? hit,
      (offsets?[last] ?? last) + 1,
    );
    final start = chars.stringBeforeLength;
    final end = text.length - chars.stringAfterLength;
    if (ranges.isNotEmpty && start <= ranges.last.$2) {
      final (prevStart, prevEnd) = ranges.removeLast();
      ranges.add((prevStart, end > prevEnd ? end : prevEnd));
    } else {
      ranges.add((start, end));
    }
  }
  return ranges;
}
