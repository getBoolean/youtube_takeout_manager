// The `:name` syntax for emojis in a search. YouTube writes a channel emoji
// as `:name:` or `:_name:`, and standard emojis have `:name:` shortcodes.

/// A character of an emoji name.
const _nameChar = r'[\w-]';

final _wordChar = RegExp(r'\w');
final _plainName = RegExp('^$_nameChar+\$');
final _token = RegExp(':_?($_nameChar+):');

/// An unfinished `:name` at the end of the text.
final _fragment = RegExp(':_?($_nameChar{2,})\$');

/// A `:name` or `:name:` in a search query.
final _queryToken = RegExp(':$_nameChar+:?');
final _underscoreToken = RegExp(':_(?=$_nameChar)');

/// Whether the `:` at [colon] in [text] can start an emoji name. In `10:30`
/// or `word:fire` it can't.
bool _startsName(String text, int colon) =>
    colon == 0 || !_wordChar.hasMatch(text[colon - 1]);

/// An unfinished `:name` being typed. [name] is lowercase; [channelOnly]
/// when typed as `:_name`, YouTube's syntax for channel emojis.
typedef EmojiFragment = ({int start, int end, String name, bool channelOnly});

/// The unfinished `:name` (at least two characters) that [text], the text
/// before the caret, ends with.
EmojiFragment? emojiFragmentAtEnd(String text) {
  final match = _fragment.firstMatch(text);
  if (match == null || !_startsName(text, match.start)) return null;
  return (
    start: match.start,
    end: match.end,
    name: match[1]!.toLowerCase(),
    channelOnly: match[0]!.startsWith(':_'),
  );
}

/// When the `:` just before [end] in [text] closes a `:name:`, where that
/// token starts and its lowercase name.
({int start, String name})? closedEmojiName(String text, int end) {
  final open = end >= 2 ? text.lastIndexOf(':', end - 2) : -1;
  if (open < 0 || !_startsName(text, open)) return null;
  final name = text.substring(open + 1, end - 1).toLowerCase();
  if (!_plainName.hasMatch(name)) return null;
  return (start: open, name: name);
}

/// The complete `:name:` and `:_name:` tokens in [text], in order. [name]
/// is as written, without colons or the underscore.
List<({int start, int end, String name})> emojiTokensIn(String text) => [
  for (final match in _token.allMatches(text))
    (start: match.start, end: match.end, name: match[1]!),
];

/// Names are inserted into `:name:` search tokens, so anything unexpected is
/// rejected rather than trusted.
bool isValidEmojiName(String name) =>
    name.length <= 64 && _plainName.hasMatch(name);

/// Rewrites YouTube's `:_name:` shortcut form to `:name:`, including a token
/// still being typed (`:_na`).
String normalizeEmojiQuery(String query) =>
    query.replaceAll(_underscoreToken, ':');

/// Whether [query] searches for custom emojis by name (`:name` or `:name:`).
/// Plain words only match visible text.
bool queryMentionsEmoji(String query) => _queryToken.hasMatch(query);

/// Whether the emoji called [name] is one that [query] searches for: its
/// `:name:` contains one of the query's `:name` / `:name:` tokens.
bool emojiMatchesQuery(String name, String query) {
  final token = ':${name.toLowerCase()}:';
  return _queryToken
      .allMatches(normalizeEmojiQuery(query).toLowerCase())
      .any((match) => token.contains(match[0]!));
}
