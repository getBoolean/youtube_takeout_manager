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

  test('channel avatars stop when the sign-in stops working', () async {
    await expectLater(
      YoutubeChannelRepository().fetchChannelThumbnails(_rejected, {'UCa'}),
      throwsA(predicate(isSignInFailure)),
    );
  });
}
