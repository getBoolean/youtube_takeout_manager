import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('fetchMyChannel', () {
    test("asks for the signed-in account's channel and returns it", () async {
      late Uri requested;
      final client = MockClient((request) async {
        requested = request.url;
        return _json({
          'items': [
            {
              'id': 'UCNvbaa8lnkDE7-qc3zcePLA',
              'snippet': {
                'title': 'Boolean',
                'customUrl': '@booleandev',
                'thumbnails': {
                  'default': {'url': 'https://yt3.example/avatar'},
                },
              },
            },
          ],
        });
      });

      final channel = await YoutubeChannelRepository().fetchMyChannel(client);

      expect(channel?.id, 'UCNvbaa8lnkDE7-qc3zcePLA');
      expect(channel?.title, 'Boolean');
      expect(channel?.handle, '@booleandev');
      expect(channel?.thumbnailUrl, 'https://yt3.example/avatar');
      expect(requested.path, endsWith('/youtube/v3/channels'));
      expect(requested.queryParameters['mine'], 'true');
    });

    test('returns null when the account has no channel', () async {
      final client = MockClient((_) async => _json({'items': <Object>[]}));

      expect(await YoutubeChannelRepository().fetchMyChannel(client), isNull);
    });

    test('lets request failures through', () async {
      final client = MockClient((_) async => http.Response('', 500));

      expect(
        YoutubeChannelRepository().fetchMyChannel(client),
        throwsA(anything),
      );
    });
  });

  group('fetchChannelSnippets', () {
    test("asks for each channel's picture and topics in one request, and "
        'reads them', () async {
      late Uri requested;
      final client = MockClient((request) async {
        requested = request.url;
        return _json({
          'items': [
            {
              'id': 'UCa',
              'snippet': {
                'description': 'Speedruns every week.',
                'thumbnails': {
                  'default': {'url': 'https://yt3.example/UCa'},
                },
              },
              'topicDetails': {
                'topicCategories': [
                  'https://en.wikipedia.org/wiki/Video_game_culture',
                  'https://en.wikipedia.org/wiki/Action_game',
                ],
              },
            },
            {
              'id': 'UCb',
              'snippet': {'title': 'No picture, no topics'},
            },
          ],
        });
      });

      final snippets = await YoutubeChannelRepository().fetchChannelSnippets(
        client,
        {'UCa', 'UCb'},
      );

      expect(requested.queryParametersAll['part'], ['snippet', 'topicDetails']);
      expect(snippets['UCa']?.thumbnailUrl, 'https://yt3.example/UCa');
      expect(snippets['UCa']?.details.topicUrls, hasLength(2));
      expect(snippets['UCa']?.details.description, 'Speedruns every week.');
      expect(snippets['UCb']?.thumbnailUrl, isNull);
      expect(snippets['UCb']?.details.topicUrls, isEmpty);
    });

    test("lets a failed request through, so its channels aren't taken to "
        'be gone', () {
      final client = MockClient((_) async => http.Response('', 500));

      expect(
        YoutubeChannelRepository().fetchChannelSnippets(client, {'UCa'}),
        throwsA(anything),
      );
    });
  });
}
