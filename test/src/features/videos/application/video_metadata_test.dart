import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/youtube_video_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

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

/// The API, holding the videos in [existing] (just v1 when null).
class _Videos extends YoutubeVideoRepository {
  final bool signInFails;
  final Set<String>? existing;

  /// The IDs asked for, per fetch.
  final requested = <Set<String>>[];

  _Videos({this.signInFails = false, this.existing});

  @override
  Stream<Video> fetchVideoMetadataStream(
    http.Client authClient,
    Set<String> videoIds,
  ) async* {
    requested.add(videoIds);
    if (signInFails) {
      throw ServerRequestFailedException(
        'invalid_grant',
        statusCode: 400,
        responseContent: {'error': 'invalid_grant'},
      );
    }
    for (final id in existing ?? const {'v1'}) {
      if (videoIds.contains(id)) yield Video(videoId: id, channelId: 'UCvideo');
    }
  }
}

class _SignIns extends SignInService {
  final failed = <String>[];

  @override
  void build() {}

  @override
  Future<void> signInFailed(String channelId) async => failed.add(channelId);
}

/// A takeout commenting on each of [videoIds].
TakeoutData _takeoutOn(Iterable<String> videoIds) => TakeoutData(
  comments: [
    for (final id in videoIds)
      Comment(
        commentId: 'c-$id',
        channelId: 'UCme',
        createdAt: DateTime.utc(2026),
        price: 0,
        videoId: id,
        rawCommentText: '',
        displayText: '',
      ),
  ],
  liveChats: const [],
  subscriptionsByChannelId: const {},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(ProviderContainer, _Clients, _SignIns)> load({
    bool signInFails = false,
    TakeoutData? takeout,
    _Videos? videos,
  }) async {
    final clients = _Clients();
    final signIns = _SignIns();
    final c = ProviderContainer(
      overrides: [
        viewedTakeoutProvider.overrideWithValue(
          AsyncData(takeout ?? _takeoutOn(['v1'])),
        ),
        readSessionChannelIdProvider.overrideWithValue('UCother'),
        googleAuthRepositoryProvider.overrideWithValue(clients),
        youtubeVideoRepositoryProvider.overrideWithValue(
          videos ?? _Videos(signInFails: signInFails),
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
    final (c, clients, _) = await load();

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

  group('fetching', () {
    // More than one batch's worth, so it takes several calls.
    final ids = [
      for (var i = 0; i <= YoutubeVideoRepository.batchSize; i++) 'v$i',
    ];
    final existing = {
      for (final (i, id) in ids.indexed)
        if (i.isEven) id,
    };
    final gone = ids.toSet().difference(existing);

    test('videos the API lacks are saved as not found, and neither they nor '
        'fetched ones are asked for again', () async {
      final first = _Videos(existing: existing);
      final (c, _, _) = await load(takeout: _takeoutOn(ids), videos: first);

      expect(first.requested.single, ids.toSet());
      final cache = c.read(videoCacheRepositoryProvider);
      expect((await cache.loadCachedVideos()).keys.toSet(), existing);
      expect(await cache.loadNotFoundIds(), gone);

      final again = _Videos(existing: existing);
      await load(takeout: _takeoutOn([...ids, 'vNew']), videos: again);

      expect(again.requested, [
        {'vNew'},
      ]);
    });

    test('videos kept on this device are not fetched', () async {
      final (c, _, _) = await load(takeout: _takeoutOn(['v1']));
      expect(
        (await c.read(videoCacheRepositoryProvider).loadCachedVideos()).keys,
        ['v1'],
      );

      final again = _Videos();
      await load(takeout: _takeoutOn(['v1', 'v2']), videos: again);

      expect(again.requested, [
        {'v2'},
      ]);
    });

    test('records one videos.list call per batch fetched', () async {
      final (c, _, _) = await load(
        takeout: _takeoutOn(ids),
        videos: _Videos(existing: existing),
      );

      final batches = (ids.length / YoutubeVideoRepository.batchSize).ceil();
      final quota = await c.read(quotaProvider.future);
      expect(
        quota.usageFor(QuotaOperation.videosList),
        batches * QuotaOperation.videosList.cost,
      );
    });
  });
}
