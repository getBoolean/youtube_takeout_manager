import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/emoji/data/youtube_emoji_name_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_lookup.dart';

const _key =
    'nqCqL7OuHfRl5bstpirPEbLuD9ldK6pyPVVzCWLjjAWk3lN5EMwErHNozzjGajgr0f3hQ0TXfA';

const _watchPage =
    '<script>var ytInitialData = {"contents":{"conversationBar":'
    '{"liveChatRenderer":{"continuations":[{"reloadContinuationData":'
    '{"continuation":"LONG_TOKEN"}}],"header":{"viewSelector":{"subMenuItems":'
    '[{"title":"Live chat replay","continuation":{"reloadContinuationData":'
    '{"continuation":"RELATIVE"}}}]}}}}}};</script>'
    '<script>{"liveBroadcastDetails":{"isLiveNow":false,'
    '"startTimestamp":"2026-04-11T18:57:29+00:00"},'
    '"INNERTUBE_CLIENT_VERSION":"2.20260101.00.00"}</script>';

/// Trimmed from a real get_live_chat_replay response.
Map<String, dynamic> _replay({Object? emoji}) => {
  'continuationContents': {
    'liveChatContinuation': {
      'actions': [
        {
          'replayChatItemAction': {
            'actions': [
              {
                'addChatItemAction': {
                  'item': {
                    'liveChatTextMessageRenderer': {
                      'message': {
                        'runs': [
                          {'text': 'not the reds again '},
                          {
                            'emoji':
                                emoji ??
                                {
                                  'emojiId':
                                      'UC62oK4gTQtOE4DvAFbFlt9Q/sCI-aLq_OdmW_9EP-bKaMQ',
                                  'shortcuts': [':_shortsad:', ':shortsad:'],
                                  'searchTerms': ['_shortsad', 'shortsad'],
                                  'image': {
                                    'thumbnails': [
                                      {
                                        'url':
                                            'https://yt3.ggpht.com/$_key=w24-h24-c-k-nd',
                                      },
                                    ],
                                  },
                                  'isCustomEmoji': true,
                                },
                          },
                          {
                            'emoji': {
                              'emojiId': '😭',
                              'shortcuts': [':sob:'],
                              'image': {
                                'thumbnails': [
                                  {'url': 'https://www.youtube.com/s/sob.svg'},
                                ],
                              },
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              },
            ],
          },
        },
      ],
    },
  },
};

void main() {
  group('parseWatchPage', () {
    test('uses the renderer continuation, not the relative view tokens', () {
      final (status, info) = parseWatchPage(_watchPage);
      expect(status, EmojiLookupStatus.ok);
      expect(info!.continuation, 'LONG_TOKEN');
      expect(info.startTime, DateTime.utc(2026, 4, 11, 18, 57, 29));
      expect(info.clientVersion, '2.20260101.00.00');
    });

    test('reports unexpectedFormat when ytInitialData is missing', () {
      expect(
        parseWatchPage('<html></html>').$1,
        EmojiLookupStatus.unexpectedFormat,
      );
    });

    test('reports noReplay for videos that are not streams', () {
      const page = '<script>var ytInitialData = {"contents":{}};</script>';
      expect(parseWatchPage(page).$1, EmojiLookupStatus.noReplay);
    });
  });

  group('parseReplayResponse', () {
    test('extracts custom emojis only, preferring the plain shortcut', () {
      final emojis = parseReplayResponse(jsonEncode(_replay()))!;
      expect(emojis.keys, [_key]);
      expect(emojis[_key]!.name, 'shortsad');
      expect(emojis[_key]!.ownerChannelId, 'UC62oK4gTQtOE4DvAFbFlt9Q');
    });

    test('returns null for responses without a chat continuation', () {
      expect(parseReplayResponse('{"error":{"code":400}}'), isNull);
      expect(parseReplayResponse('not json'), isNull);
    });

    test('skips malformed or unsafe emoji entries', () {
      for (final emoji in [
        {'isCustomEmoji': true, 'shortcuts': 'oops', 'image': 5},
        {
          'isCustomEmoji': true,
          'shortcuts': [':bad name!:'],
          'image': {
            'thumbnails': [
              {'url': 'https://yt3.ggpht.com/$_key'},
            ],
          },
        },
      ]) {
        expect(parseReplayResponse(jsonEncode(_replay(emoji: emoji))), isEmpty);
      }
    });
  });

  group('resolveFromVideo', () {
    final times = [DateTime.utc(2026, 4, 11, 20, 47)];

    test('resolves names end to end', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET') return http.Response(_watchPage, 200);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['continuation'], 'LONG_TOKEN');
        return http.Response(
          jsonEncode(_replay()),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final result = await YoutubeEmojiNameRepository(
        client,
      ).resolveFromVideo('vid', times, wantedKeys: {_key});
      expect(result.status, EmojiLookupStatus.ok);
      expect(result.found[_key]!.name, 'shortsad');
    });

    test('flags unexpected response formats', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET') return http.Response(_watchPage, 200);
        return http.Response('{"somethingNew":{}}', 200);
      });
      final result = await YoutubeEmojiNameRepository(
        client,
      ).resolveFromVideo('vid', times, wantedKeys: {_key});
      expect(result.status, EmojiLookupStatus.unexpectedFormat);
    });

    test(
      'reports rate limiting and connection failures as network errors',
      () async {
        final limited = MockClient((_) async => http.Response('', 429));
        expect(
          (await YoutubeEmojiNameRepository(
            limited,
          ).resolveFromVideo('v', times, wantedKeys: {_key})).status,
          EmojiLookupStatus.networkError,
        );
        final offline = MockClient(
          (_) async => throw http.ClientException('offline'),
        );
        expect(
          (await YoutubeEmojiNameRepository(
            offline,
          ).resolveFromVideo('v', times, wantedKeys: {_key})).status,
          EmojiLookupStatus.networkError,
        );
      },
    );
  });
}
