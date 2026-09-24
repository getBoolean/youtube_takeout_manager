import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';

part 'youtube_emoji_name_repository.g.dart';

@Riverpod(keepAlive: true)
YoutubeEmojiNameRepository youtubeEmojiNameRepository(Ref ref) {
  final repository = YoutubeEmojiNameRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// A custom emoji name learned from YouTube's live chat data.
class ResolvedEmoji {
  /// Name without colons or leading underscore, e.g. `shortsad`.
  final String name;

  /// Channel that owns the emoji (prefix of YouTube's `emojiId`).
  final String? ownerChannelId;

  const ResolvedEmoji({required this.name, this.ownerChannelId});

  static ResolvedEmoji? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final owner = json['owner'];
    if (name is! String || !isValidEmojiName(name)) return null;
    return ResolvedEmoji(
      name: name,
      ownerChannelId: owner is String ? owner : null,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'owner': ownerChannelId};
}

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

const _defaultClientVersion = '2.20260922.01.00';
const _requestTimeout = Duration(seconds: 15);
const _userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

/// Resolves custom emoji names (which Takeout omits) by reading the live chat
/// replay around the time the user sent a message containing the emoji.
///
/// Uses YouTube's undocumented innertube endpoints (no API key or quota).
/// Never throws: every failure is reported through [EmojiLookupStatus] so the
/// caller can back off. Not usable on web because of CORS.
class YoutubeEmojiNameRepository {
  final http.Client _client;

  YoutubeEmojiNameRepository([http.Client? client])
    : _client = client ?? http.Client();

  void close() => _client.close();

  /// Returns every custom emoji seen in the replay of [videoId] near
  /// [messageTimes], keyed by `emojiKey`. Stops early once all [wantedKeys]
  /// are found.
  Future<EmojiLookupResult> resolveFromVideo(
    String videoId,
    List<DateTime> messageTimes, {
    required Set<String> wantedKeys,
    int maxRequests = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    final found = <String, ResolvedEmoji>{};
    try {
      final page = await _client
          .get(
            Uri.https('www.youtube.com', '/watch', {'v': videoId}),
            headers: {
              'User-Agent': _userAgent,
              'Accept-Language': 'en',
              'Cookie': 'SOCS=CAI; CONSENT=YES+',
            },
          )
          .timeout(_requestTimeout);
      if (page.statusCode == 404) {
        return const EmojiLookupResult(EmojiLookupStatus.noReplay);
      }
      if (page.statusCode != 200) {
        return const EmojiLookupResult(EmojiLookupStatus.networkError);
      }
      final (pageStatus, info) = await compute(parseWatchPage, page.body);
      if (info == null) return EmojiLookupResult(pageStatus);

      final times = [...messageTimes]..sort();
      var requests = 0;
      var parsedResponses = 0;
      DateTime? lastRequested;
      for (final time in times) {
        if (requests >= maxRequests) break;
        if (wantedKeys.every(found.containsKey)) break;
        // One replay response spans roughly a minute of chat.
        if (lastRequested != null &&
            time.difference(lastRequested) < const Duration(seconds: 30)) {
          continue;
        }
        if (requests > 0) await Future<void>.delayed(delay);
        requests++;
        lastRequested = time;

        final offsetMs = time.difference(info.startTime).inMilliseconds - 5000;
        final response = await _client
            .post(
              Uri.https(
                'www.youtube.com',
                '/youtubei/v1/live_chat/get_live_chat_replay',
                {'prettyPrint': 'false'},
              ),
              headers: {
                'User-Agent': _userAgent,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'context': {
                  'client': {
                    'clientName': 'WEB',
                    'clientVersion': info.clientVersion,
                    'hl': 'en',
                  },
                },
                'continuation': info.continuation,
                'currentPlayerState': {
                  'playerOffsetMs': '${offsetMs < 0 ? 0 : offsetMs}',
                },
              }),
            )
            .timeout(_requestTimeout);
        if (response.statusCode == 429 || response.statusCode >= 500) {
          return EmojiLookupResult(EmojiLookupStatus.networkError, found);
        }
        if (response.statusCode != 200) continue;
        final emojis = await compute(parseReplayResponse, response.body);
        if (emojis == null) continue;
        parsedResponses++;
        found.addAll(emojis);
      }
      if (requests > 0 && parsedResponses == 0) {
        return EmojiLookupResult(EmojiLookupStatus.unexpectedFormat, found);
      }
      return EmojiLookupResult(EmojiLookupStatus.ok, found);
    } on TimeoutException {
      return EmojiLookupResult(EmojiLookupStatus.networkError, found);
    } on http.ClientException {
      return EmojiLookupResult(EmojiLookupStatus.networkError, found);
    } catch (e) {
      debugPrint('Emoji name lookup failed for $videoId: $e');
      return EmojiLookupResult(EmojiLookupStatus.unexpectedFormat, found);
    }
  }
}

final _startTimestamp = RegExp(r'"startTimestamp":"([^"]+)"');
final _clientVersion = RegExp(r'"INNERTUBE_CLIENT_VERSION":"([^"]+)"');
final _initialData = RegExp(r'ytInitialData\s*=\s*(\{.+?\});\s*</script>');
final _validEmojiName = RegExp(r'^[\w-]+$');

/// Names are inserted into `:name:` search tokens, so anything unexpected is
/// rejected rather than trusted.
bool isValidEmojiName(String name) =>
    name.length <= 64 && _validEmojiName.hasMatch(name);

/// Extracts the replay continuation, stream start and client version from a
/// watch page.
///
/// A page without `ytInitialData` means YouTube changed its markup
/// ([EmojiLookupStatus.unexpectedFormat]); a normal page without a stream
/// start or chat is [EmojiLookupStatus.noReplay].
@visibleForTesting
(EmojiLookupStatus, LiveChatReplayInfo?) parseWatchPage(String html) {
  try {
    final dataJson = _initialData.firstMatch(html)?[1];
    if (dataJson == null) return (EmojiLookupStatus.unexpectedFormat, null);
    final data = jsonDecode(dataJson);

    final start = _startTimestamp.firstMatch(html)?[1];
    final startTime = start == null ? null : DateTime.tryParse(start);
    if (startTime == null) return (EmojiLookupStatus.noReplay, null);

    final chat = _findKey(data, 'liveChatRenderer');
    if (chat == null) return (EmojiLookupStatus.noReplay, null);
    final continuation = _pickContinuation(chat);
    if (continuation == null) return (EmojiLookupStatus.unexpectedFormat, null);

    return (
      EmojiLookupStatus.ok,
      LiveChatReplayInfo(
        continuation: continuation,
        startTime: startTime,
        clientVersion:
            _clientVersion.firstMatch(html)?[1] ?? _defaultClientVersion,
      ),
    );
  } catch (_) {
    return (EmojiLookupStatus.unexpectedFormat, null);
  }
}

/// Parses a `get_live_chat_replay` response body. Returns null when it isn't
/// a live chat continuation at all.
@visibleForTesting
Map<String, ResolvedEmoji>? parseReplayResponse(String body) {
  try {
    final json = jsonDecode(body);
    if (_findKey(json, 'liveChatContinuation') == null) return null;
    return extractCustomEmojis(json);
  } catch (_) {
    return null;
  }
}

/// The renderer's own `continuations` entry identifies the video. The view
/// selector's "Top chat" / "Live chat" tokens are relative to an existing
/// chat session and fail when used on their own.
String? _pickContinuation(Object chat) {
  if (chat is! Map) return null;
  return _reloadContinuation(chat['continuations']);
}

String? _reloadContinuation(Object? node) {
  final data = _findKey(node, 'reloadContinuationData');
  if (data is Map && data['continuation'] is String) {
    return data['continuation'] as String;
  }
  return null;
}

/// Depth-first search for the first value stored under [key].
Object? _findKey(Object? node, String key) {
  if (node is Map) {
    if (node.containsKey(key)) return node[key];
    for (final value in node.values) {
      final found = _findKey(value, key);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final value in node) {
      final found = _findKey(value, key);
      if (found != null) return found;
    }
  }
  return null;
}

/// Collects every custom emoji object (`isCustomEmoji: true`) anywhere in a
/// live chat response, keyed by `emojiKey` of its image URL. Malformed
/// entries are skipped.
@visibleForTesting
Map<String, ResolvedEmoji> extractCustomEmojis(Object? node) {
  final result = <String, ResolvedEmoji>{};
  void walk(Object? n) {
    if (n is Map) {
      final emoji = n['emoji'];
      if (emoji is Map && emoji['isCustomEmoji'] == true) {
        final resolved = _parseEmoji(emoji);
        if (resolved != null) result[resolved.$1] = resolved.$2;
      }
      n.values.forEach(walk);
    } else if (n is List) {
      n.forEach(walk);
    }
  }

  walk(node);
  return result;
}

(String, ResolvedEmoji)? _parseEmoji(Map emoji) {
  final image = emoji['image'];
  final thumbnails = image is Map ? image['thumbnails'] : null;
  if (thumbnails is! List || thumbnails.isEmpty) return null;
  final thumbnail = thumbnails.first;
  final url = thumbnail is Map ? thumbnail['url'] : null;
  if (url is! String) return null;
  final key = emojiKey(url);
  if (key.isEmpty) return null;

  final rawShortcuts = emoji['shortcuts'];
  final shortcuts = rawShortcuts is List
      ? rawShortcuts.whereType<String>().toList()
      : const <String>[];
  final shortcut =
      shortcuts.where((s) => !s.startsWith(':_')).firstOrNull ??
      shortcuts.firstOrNull;
  if (shortcut == null) return null;
  final name = shortcut.replaceAll(':', '').replaceFirst(RegExp('^_'), '');
  if (!isValidEmojiName(name)) return null;

  final emojiId = emoji['emojiId'];
  final owner = emojiId is String && emojiId.contains('/')
      ? emojiId.substring(0, emojiId.indexOf('/'))
      : null;
  return (key, ResolvedEmoji(name: name, ownerChannelId: owner));
}
