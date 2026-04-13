import 'dart:convert';

import 'package:flutter/widgets.dart';

/// A parsed segment of a comment/live chat text field.
sealed class CommentSegment {
  const CommentSegment();
}

class TextSegment extends CommentSegment {
  final String text;
  const TextSegment(this.text);
}

class EmojiSegment extends CommentSegment {
  final String url;
  const EmojiSegment(this.url);
}

/// Parses the JSON-encoded comment/live chat text field from Google Takeout CSVs
/// into a list of [CommentSegment]s for rich rendering.
List<CommentSegment> parseCommentSegments(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];

  try {
    final jsonArray = jsonDecode('[$trimmed]') as List;
    final segments = <CommentSegment>[];
    for (final item in jsonArray) {
      final map = item as Map<String, dynamic>;
      final text = map['text'] as String? ?? '';
      if (text.isEmpty && map['emoji'] is Map) {
        final emoji = map['emoji'] as Map<String, dynamic>;
        final url = emoji['customEmojiUrl'] as String?;
        if (url != null) {
          segments.add(EmojiSegment(url));
          continue;
        }
      }
      if (text.isNotEmpty) {
        segments.add(TextSegment(text));
      }
    }
    return segments;
  } catch (_) {
    return [TextSegment(raw)];
  }
}

/// Parses the JSON-encoded comment/live chat text field from Google Takeout CSVs.
///
/// Returns the concatenated plain text from all segments. Custom emoji are
/// represented as a placeholder character.
String parseCommentText(String raw) {
  final segments = parseCommentSegments(raw);
  return segments
      .map(
        (s) => switch (s) {
          TextSegment(:final text) => text,
          EmojiSegment() => '\u{1F600}',
        },
      )
      .join();
}

/// Builds an [InlineSpan] list from raw comment JSON for use in [Text.rich].
List<InlineSpan> buildCommentSpans(String raw, {required double emojiSize}) {
  final segments = parseCommentSegments(raw);
  if (segments.isEmpty) return const [];

  return segments
      .map<InlineSpan>(
        (s) => switch (s) {
          TextSegment(:final text) => TextSpan(text: text),
          EmojiSegment(:final url) => WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
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
