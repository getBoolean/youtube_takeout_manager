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
///
/// With [emojiNames] false (a search that isn't looking for emojis, see
/// [queryMentionsEmoji]) each emoji becomes a placeholder that matches
/// nothing, so a word can't match an emoji's name or run across one.
String searchableCommentText(
  String raw,
  Map<String, String> namesByKey, {
  bool emojiNames = true,
}) {
  return parseCommentSegments(raw).map((s) {
    switch (s) {
      case TextSegment(:final text):
        return text;
      case EmojiSegment(:final url):
        if (!emojiNames) return '\u{FFFC}';
        final key = emojiKey(url);
        return ':${namesByKey[key] ?? fallbackEmojiName(key)}:';
    }
  }).join();
}

/// Lowercases [text] and drops U+FE0F (emoji presentation selector) so `❤️`
/// and `❤` match each other. Apply to both the query and the searched text.
String foldForSearch(String text) {
  final lower = text.toLowerCase();
  return lower.contains('\u{FE0F}') ? lower.replaceAll('\u{FE0F}', '') : lower;
}

final _underscoreEmojiToken = RegExp(r':_(?=[\w-])');

/// Rewrites YouTube's `:_name:` shortcut form to `:name:`, including a token
/// still being typed (`:_na`).
String normalizeEmojiQuery(String query) =>
    query.replaceAll(_underscoreEmojiToken, ':');

final _emojiQueryToken = RegExp(r':[\w-]+:?');

/// Whether [query] searches for custom emojis by name (`:name` or `:name:`).
/// Plain words only match visible text.
bool queryMentionsEmoji(String query) => _emojiQueryToken.hasMatch(query);

/// Whether the emoji called [name] is one that [query] searches for: its
/// `:name:` contains one of the query's `:name` / `:name:` tokens.
bool emojiMatchesQuery(String name, String query) {
  final token = ':${name.toLowerCase()}:';
  return _emojiQueryToken
      .allMatches(normalizeEmojiQuery(query).toLowerCase())
      .any((match) => token.contains(match[0]!));
}

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
