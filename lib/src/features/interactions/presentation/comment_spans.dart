import 'package:flutter/widgets.dart';

import '../domain/comment_segments.dart';

/// The custom emojis directly before and after one, with no text between.
typedef AdjacentEmojis = ({String? previousUrl, String? nextUrl});

typedef EmojiSpanBuilder =
    Widget Function(String url, double size, AdjacentEmojis adjacent);

/// Builds an [InlineSpan] list from raw comment JSON for use in [Text.rich].
///
/// [emojiBuilder] replaces the default emoji image (e.g. to add a preview).
List<InlineSpan> buildCommentSpans(
  String raw, {
  required double emojiSize,
  EmojiSpanBuilder? emojiBuilder,
}) {
  final segments = parseCommentSegments(raw);
  if (segments.isEmpty) return const [];

  String? emojiUrlAt(int i) =>
      switch (i >= 0 && i < segments.length ? segments[i] : null) {
        EmojiSegment(:final url) => url,
        _ => null,
      };

  return segments.indexed
      .map<InlineSpan>(
        (entry) => switch (entry.$2) {
          TextSegment(:final text) => TextSpan(text: text),
          EmojiSegment(:final url) => WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child:
                emojiBuilder?.call(url, emojiSize, (
                  previousUrl: emojiUrlAt(entry.$1 - 1),
                  nextUrl: emojiUrlAt(entry.$1 + 1),
                )) ??
                Image.network(
                  url,
                  width: emojiSize,
                  height: emojiSize,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, _, _) =>
                      SizedBox(width: emojiSize, height: emojiSize),
                ),
          ),
        },
      )
      .toList();
}
