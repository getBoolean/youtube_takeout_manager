import 'package:youtube_takeout_manager/src/features/interactions/domain/comment_segments.dart';
import 'emoji_key.dart';

/// Plain text used for search matching. Custom emoji are written as
/// `:name:` using [namesByKey], falling back to [fallbackEmojiName].
///
/// With [emojiNames] false (a search that isn't looking for emojis, see
/// `queryMentionsEmoji`) each emoji becomes a placeholder that matches
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
