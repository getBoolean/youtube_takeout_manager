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

/// Whether [url] is an image URL. For emojis it couldn't export, Takeout
/// writes "Failed to get emoji URL" instead.
bool isEmojiImageUrl(String url) {
  final scheme = Uri.tryParse(url)?.scheme;
  return scheme == 'https' || scheme == 'http';
}

/// Name used for an emoji whose real name could not be resolved.
String fallbackEmojiName(String key) =>
    'emoji_${key.substring(0, key.length < 6 ? key.length : 6)}';
