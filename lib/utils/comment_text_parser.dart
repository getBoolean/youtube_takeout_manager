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

/// Stable identifier for a custom emoji image, shared between the Takeout
/// `customEmojiUrl` and the URLs returned by YouTube's live chat API.
///
/// Both forms end in the same path segment; YouTube URLs may add a size
/// suffix (`=w24-h24-c-k-nd`) and use a different host.
String emojiKey(String url) {
  final path = Uri.tryParse(url)?.pathSegments;
  final last = (path != null && path.isNotEmpty) ? path.last : url;
  final eq = last.indexOf('=');
  return eq == -1 ? last : last.substring(0, eq);
}

/// Name used for an emoji whose real name could not be resolved.
String fallbackEmojiName(String key) =>
    'emoji_${key.substring(0, key.length < 6 ? key.length : 6)}';

/// Plain text used for search matching. Custom emoji are written as
/// `:name:` using [namesByKey], falling back to [fallbackEmojiName].
String searchableCommentText(String raw, Map<String, String> namesByKey) {
  return parseCommentSegments(raw).map((s) {
    switch (s) {
      case TextSegment(:final text):
        return text;
      case EmojiSegment(:final url):
        final key = emojiKey(url);
        return ':${namesByKey[key] ?? fallbackEmojiName(key)}:';
    }
  }).join();
}

final _underscoreEmojiToken = RegExp(r':_([\w-]+):');

/// Rewrites YouTube's `:_name:` shortcut form to `:name:`.
String normalizeEmojiQuery(String query) =>
    query.replaceAllMapped(_underscoreEmojiToken, (m) => ':${m[1]}:');

/// Builds an [InlineSpan] list from raw comment JSON for use in [Text.rich].
///
/// [emojiBuilder] replaces the default emoji image (e.g. to add a preview).
List<InlineSpan> buildCommentSpans(
  String raw, {
  required double emojiSize,
  Widget Function(String url, double size)? emojiBuilder,
}) {
  final segments = parseCommentSegments(raw);
  if (segments.isEmpty) return const [];

  return segments
      .map<InlineSpan>(
        (s) => switch (s) {
          TextSegment(:final text) => TextSpan(text: text),
          EmojiSegment(:final url) => WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child:
                emojiBuilder?.call(url, emojiSize) ??
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
