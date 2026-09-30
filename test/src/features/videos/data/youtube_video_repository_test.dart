import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/data/quota_errors.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/youtube_video_repository.dart';

/// YouTube's answer to a token it no longer accepts.
final _rejected = MockClient(
  (_) async => http.Response(
    jsonEncode({
      'error': {'code': 401, 'message': 'Invalid Credentials'},
    }),
    401,
    headers: {'content-type': 'application/json; charset=utf-8'},
  ),
);

/// YouTube's answer once the day's quota is used up.
final _quotaUsedUp = MockClient(
  (_) async => http.Response(
    jsonEncode({
      'error': {
        'code': 403,
        'message':
            'The request cannot be completed because you have '
            'exceeded your quota.',
        'errors': [
          {'reason': 'quotaExceeded', 'domain': 'youtube.quota'},
        ],
      },
    }),
    403,
    headers: {'content-type': 'application/json; charset=utf-8'},
  ),
);

void main() {
  test('video details stop when the quota is used up', () async {
    await expectLater(
      YoutubeVideoRepository().fetchVideoMetadataStream(_quotaUsedUp, {
        'v1',
      }).toList(),
      throwsA(predicate(isQuotaExceeded)),
    );
  });

  test('channel pictures stop when the quota is used up', () async {
    await expectLater(
      YoutubeChannelRepository().fetchChannelThumbnails(_quotaUsedUp, {'UCa'}),
      throwsA(predicate(isQuotaExceeded)),
    );
  });

  test('video details stop when the sign-in stops working', () async {
    await expectLater(
      YoutubeVideoRepository().fetchVideoMetadataStream(_rejected, {
        'v1',
      }).toList(),
      throwsA(predicate(isSignInFailure)),
    );
  });

  test('other failures skip the batch', () async {
    final failing = MockClient((_) async => http.Response('', 500));
    expect(
      await YoutubeVideoRepository().fetchVideoMetadataStream(failing, {
        'v1',
      }).toList(),
      isEmpty,
    );
  });

  group('video formats', () {
    test("ask only for each video's length and shape, and read them", () async {
      final asked = <Uri>[];
      final client = MockClient((request) async {
        asked.add(request.url);
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'short1',
                'contentDetails': {'duration': 'PT45S'},
                'player': {'embedWidth': '270', 'embedHeight': '480'},
              },
              {
                'id': 'long1',
                'contentDetails': {'duration': 'PT12M3S'},
                'player': {'embedWidth': '480', 'embedHeight': '270'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final formats = await YoutubeVideoRepository().fetchVideoFormats(client, [
        'short1',
        'long1',
        'gone',
      ]).toList();

      expect(
        {for (final (id, f) in formats) id: f.isShort},
        {'short1': true, 'long1': false},
      );
      final query = asked.single.queryParametersAll;
      expect(query['part'], containsAll(['contentDetails', 'player']));
      expect(query['id'], ['short1', 'long1', 'gone']);
      // The shape only comes back for a player size asked for.
      expect(query.keys, anyOf(contains('maxWidth'), contains('maxHeight')));
    });

    test(
      'are asked for 50 videos at a time, and each answer counted',
      () async {
        var requests = 0;
        var answers = 0;
        final client = MockClient((request) async {
          requests++;
          expect(
            request.url.queryParametersAll['id']!.length,
            lessThanOrEqualTo(YoutubeVideoRepository.batchSize),
          );
          return http.Response(
            jsonEncode({'items': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        await YoutubeVideoRepository().fetchVideoFormats(client, [
          for (var i = 0; i < YoutubeVideoRepository.batchSize + 1; i++) 'v$i',
        ], onResponse: () => answers++).toList();

        expect((requests, answers), (2, 2));
      },
    );

    test('stop when the quota is used up', () async {
      await expectLater(
        YoutubeVideoRepository().fetchVideoFormats(_quotaUsedUp, [
          'v1',
        ]).toList(),
        throwsA(predicate(isQuotaExceeded)),
      );
    });

    test('stop when the sign-in stops working', () async {
      await expectLater(
        YoutubeVideoRepository().fetchVideoFormats(_rejected, ['v1']).toList(),
        throwsA(predicate(isSignInFailure)),
      );
    });
  });

  test('channel avatars stop when the sign-in stops working', () async {
    await expectLater(
      YoutubeChannelRepository().fetchChannelThumbnails(_rejected, {'UCa'}),
      throwsA(predicate(isSignInFailure)),
    );
  });
}
