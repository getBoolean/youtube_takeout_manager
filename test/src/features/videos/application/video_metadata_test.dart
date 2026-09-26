import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/youtube_video_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

final _takeout = TakeoutData(
  comments: [
    Comment(
      commentId: 'c1',
      channelId: 'UCme',
      createdAt: DateTime.utc(2026),
      price: 0,
      videoId: 'v1',
      rawCommentText: '',
      displayText: '',
    ),
  ],
  liveChats: const [],
  subscriptionsByChannelId: const {},
);

class _Clients extends GoogleAuthRepository {
  final used = <String>[];

  @override
  http.Client getAuthenticatedClient(String channelId) {
    used.add(channelId);
    return http.Client();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Videos extends YoutubeVideoRepository {
  final bool signInFails;

  _Videos({this.signInFails = false});

  @override
  Stream<Video> fetchVideoMetadataStream(
    http.Client authClient,
    Set<String> videoIds,
  ) async* {
    if (signInFails) {
      throw ServerRequestFailedException(
        'invalid_grant',
        statusCode: 400,
        responseContent: {'error': 'invalid_grant'},
      );
    }
    yield const Video(videoId: 'v1', channelId: 'UCvideo');
  }
}

class _SignIns extends SignInService {
  final failed = <String>[];

  @override
  void build() {}

  @override
  Future<void> signInFailed(String channelId) async => failed.add(channelId);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(ProviderContainer, _Clients, _SignIns)> load({
    required bool signInFails,
  }) async {
    final clients = _Clients();
    final signIns = _SignIns();
    final c = ProviderContainer(
      overrides: [
        viewedTakeoutProvider.overrideWithValue(AsyncData(_takeout)),
        readSessionChannelIdProvider.overrideWithValue('UCother'),
        googleAuthRepositoryProvider.overrideWithValue(clients),
        youtubeVideoRepositoryProvider.overrideWithValue(
          _Videos(signInFails: signInFails),
        ),
        signInServiceProvider.overrideWith(() => signIns),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(videoMetadataProvider, (_, _) {})
      ..listen(videoTitleFetcherProvider, (_, _) {});
    // Lets the fetch after the cached videos finish.
    for (var i = 0; i < 20; i++) {
      await pumpEventQueue();
    }
    return (c, clients, signIns);
  }

  test('loads video details with whichever sign-in is available', () async {
    final (c, clients, _) = await load(signInFails: false);

    expect(clients.used, ['UCother']);
    expect(await c.read(videoCacheRepositoryProvider).loadCachedVideos(), {
      'v1': const Video(videoId: 'v1', channelId: 'UCvideo'),
    });
  });

  test('a sign-in that stops working is reported, and its videos are not '
      'taken to be gone', () async {
    final (c, _, signIns) = await load(signInFails: true);

    expect(signIns.failed, ['UCother']);
    expect(
      await c.read(videoCacheRepositoryProvider).loadNotFoundIds(),
      isEmpty,
    );
  });
}
