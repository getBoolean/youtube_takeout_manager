import 'resolved_emoji.dart';

/// Data needed from a watch page to request its live chat replay.
class LiveChatReplayInfo {
  final String continuation;
  final DateTime startTime;
  final String clientVersion;

  const LiveChatReplayInfo({
    required this.continuation,
    required this.startTime,
    required this.clientVersion,
  });
}

enum EmojiLookupStatus {
  /// Requests succeeded (emojis may or may not have been found).
  ok,

  /// The video has no chat replay (not a stream, private, members-only...).
  noReplay,

  /// Offline, timed out or rate limited; worth retrying later.
  networkError,

  /// YouTube's page or response no longer looks like what we parse. Likely an
  /// upstream change; callers should stop making requests.
  unexpectedFormat,
}

class EmojiLookupResult {
  final EmojiLookupStatus status;
  final Map<String, ResolvedEmoji> found;

  const EmojiLookupResult(this.status, [this.found = const {}]);
}
