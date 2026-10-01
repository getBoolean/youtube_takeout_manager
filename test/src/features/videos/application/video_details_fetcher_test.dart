import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/youtube/v3.dart' show DetailedApiRequestError;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_details_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/youtube_video_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

class _Clients extends GoogleAuthRepository {
  @override
  http.Client getAuthenticatedClient(String channelId) => http.Client();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The API, holding every video but those in [gone], answering in batches
/// as the real one does.
class _Videos extends YoutubeVideoRepository {
  final Set<String> gone;

  /// Whether YouTube refuses every request after the first, its quota used
  /// up.
  final bool quotaRunsOut;

  /// The IDs asked for, by request.
  final requests = <List<String>>[];

  _Videos({this.gone = const {}, this.quotaRunsOut = false});

  @override
  Stream<Video> fetchVideoMetadataStream(
    http.Client authClient,
    Set<String> videoIds, {
    void Function()? onResponse,
  }) async* {
    const size = YoutubeVideoRepository.batchSize;
    final ids = videoIds.toList();
    for (var i = 0; i < ids.length; i += size) {
      if (i > 0 && quotaRunsOut) {
        throw DetailedApiRequestError(403, 'You have exceeded your quota.');
      }
      final batch = ids.skip(i).take(size).toList();
      requests.add(batch);
      onResponse?.call();
      for (final id in batch) {
        if (!gone.contains(id)) {
          yield Video(videoId: id, channelId: 'UCa', description: 'About $id');
        }
      }
    }
  }
}

class _SignIns extends SignInService {
  @override
  void build() {}

  @override
  Future<void> signInFailed(String channelId) async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container({String? session = 'UCme', _Videos? videos}) {
    final c = ProviderContainer(
      overrides: [
        readSessionChannelIdProvider.overrideWithValue(session),
        googleAuthRepositoryProvider.overrideWithValue(_Clients()),
        youtubeVideoRepositoryProvider.overrideWithValue(videos ?? _Videos()),
        signInServiceProvider.overrideWith(_SignIns.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(videoMetadataProvider, (_, _) {});
    return c;
  }

  Future<void> fetch(ProviderContainer c, Iterable<String> ids) =>
      c.read(videoDetailsFetcherProvider.notifier).fetch(ids);

  test('signed out, nothing is asked for', () async {
    final videos = _Videos();
    final c = container(session: null, videos: videos);

    await fetch(c, ['v1']);

    expect(videos.requests, isEmpty);
  });

  test('the videos are kept, with their descriptions', () async {
    final c = container();

    await fetch(c, ['v1', 'v2']);

    final kept = await c.read(videoCacheRepositoryProvider).loadCachedVideos();
    expect(kept['v1']?.description, contains('v1'));
    expect(c.read(videoMetadataProvider).value?.keys, containsAll(['v1']));
  });

  test('each request is counted against the quota', () async {
    final videos = _Videos();
    final c = container(videos: videos);

    await fetch(c, [for (var i = 0; i < 120; i++) 'v$i']);

    expect(videos.requests, hasLength(3));
    final quota = await c.read(quotaProvider.future);
    expect(
      quota.usageFor(QuotaOperation.videosList),
      3 * QuotaOperation.videosList.cost,
    );
  });

  test('kept videos and ones YouTube lacks are not asked for again', () async {
    final videos = _Videos(gone: {'gone'});
    final c = container(videos: videos);
    await fetch(c, ['v1', 'gone']);
    expect(await c.read(videoCacheRepositoryProvider).loadNotFoundIds(), {
      'gone',
    });
    videos.requests.clear();

    await fetch(c, ['v1', 'gone', 'v2']);

    expect(videos.requests, [
      ['v2'],
    ]);
  });

  test('running out of quota shows it used up and keeps what came', () async {
    final c = container(videos: _Videos(quotaRunsOut: true));

    await fetch(c, [for (var i = 0; i < 60; i++) 'v$i']);

    expect((await c.read(quotaProvider.future)).usedUp, isTrue);
    final kept = await c.read(videoCacheRepositoryProvider).loadCachedVideos();
    expect(kept, hasLength(YoutubeVideoRepository.batchSize));
    expect(
      await c.read(videoCacheRepositoryProvider).loadNotFoundIds(),
      isEmpty,
    );
  });

  test(
    'videos YouTube lacks noted from two places at once are all kept',
    () async {
      final cache = container().read(videoCacheRepositoryProvider);

      await Future.wait([
        cache.addNotFoundIds({'a'}),
        cache.addNotFoundIds({'b'}),
      ]);

      expect(await cache.loadNotFoundIds(), {'a', 'b'});
    },
  );
}
