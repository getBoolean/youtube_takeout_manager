import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/youtube/v3.dart' show DetailedApiRequestError;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_shown.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/application/watched_video_format_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_format_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/video_format_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/data/youtube_video_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video_format.dart';

class _Clients extends GoogleAuthRepository {
  @override
  http.Client getAuthenticatedClient(String channelId) => http.Client();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _short = VideoFormat(seconds: 40, shape: VideoShape.tall);
const _long = VideoFormat(seconds: 900, shape: VideoShape.wide);

/// The API, knowing the videos in [known], answering in batches.
class _Videos extends YoutubeVideoRepository {
  final Map<String, VideoFormat> known;

  /// Whether YouTube refuses every request after the first, its quota used
  /// up.
  final bool quotaRunsOut;

  /// Which batch fails, as the API does when YouTube errors on one request:
  /// no answer, and on to the next batch.
  final int? failingBatch;

  /// The IDs asked for, in order.
  final asked = <String>[];

  _Videos(this.known, {this.quotaRunsOut = false, this.failingBatch});

  @override
  Stream<(String, VideoFormat)> fetchVideoFormats(
    http.Client authClient,
    List<String> videoIds, {
    void Function(List<String> batch)? onResponse,
  }) async* {
    const size = YoutubeVideoRepository.batchSize;
    for (var i = 0; i < videoIds.length; i += size) {
      if (i > 0 && quotaRunsOut) {
        throw DetailedApiRequestError(403, 'You have exceeded your quota.');
      }
      final batch = videoIds.skip(i).take(size).toList();
      asked.addAll(batch);
      if (i ~/ size == failingBatch) continue;
      onResponse?.call(batch);
      for (final id in batch) {
        if (known[id] case final format?) yield (id, format);
      }
    }
  }
}

class _Fixed extends TakeoutHistoryNotifier {
  _Fixed(this.history);

  final TakeoutHistory history;

  @override
  Future<LoadedHistory?> build() async => LoadedHistory.of(history);
}

WatchEntry _watch(String id, {String? url}) => WatchEntry(
  time: DateTime.utc(2026, 4, 12),
  kind: WatchKind.video,
  title: 'Video $id',
  url: url ?? 'https://www.youtube.com/watch?v=$id',
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await pumpEventQueue();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Newest first.
  final history = TakeoutHistory(
    watches: [_watch('new'), _watch('mid'), _watch('new'), _watch('old')],
  );

  ProviderContainer container(
    _Videos videos, {
    String? session = 'UCme',
    TakeoutHistory? watched,
  }) {
    final c = ProviderContainer(
      overrides: [
        takeoutHistoryProvider.overrideWith(() => _Fixed(watched ?? history)),
        readSessionChannelIdProvider.overrideWithValue(session),
        googleAuthRepositoryProvider.overrideWithValue(_Clients()),
        youtubeVideoRepositoryProvider.overrideWithValue(videos),
      ],
    );
    addTearDown(c.dispose);
    c.listen(watchedVideoFormatFetcherProvider, (_, _) {});
    return c;
  }

  final all = {'new': _short, 'mid': _long, 'old': _long};

  test('nothing is asked for until the history is shown', () async {
    final videos = _Videos(all);
    final c = container(videos);
    await _settle();
    expect(videos.asked, isEmpty);

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(videos.asked, ['new', 'mid', 'old']);
    expect(c.read(videoFormatsProvider).value?['new']?.isShort, isTrue);
  });

  test('signed out, nothing is asked for', () async {
    final videos = _Videos(all);
    final c = container(videos, session: null);

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(videos.asked, isEmpty);
  });

  test('videos watched through a Shorts link are known without asking', () {
    final videos = _Videos(all);
    final c = container(
      videos,
      watched: TakeoutHistory(
        watches: [
          _watch('s1', url: 'https://www.youtube.com/shorts/s1'),
          _watch('mid'),
        ],
      ),
    );

    c.read(historyShownProvider.notifier).markShown();
    return _settle().then((_) => expect(videos.asked, ['mid']));
  });

  test('what was fetched is kept, and neither it nor videos YouTube lacks '
      'are asked for again', () async {
    final first = container(_Videos({'new': _short}));
    first.read(historyShownProvider.notifier).markShown();
    await _settle();
    final cache = first.read(videoFormatCacheRepositoryProvider);
    expect((await cache.loadFormats()).keys, ['new']);
    expect(await cache.loadNotFoundIds(), {'mid', 'old'});
    first.dispose();

    final again = _Videos(all);
    final c = container(again);
    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(again.asked, isEmpty);
    expect(c.read(videoFormatsProvider).value?.keys, ['new']);
  });

  test('each answer counts against the quota', () async {
    final watched = TakeoutHistory(
      watches: [
        for (var i = 0; i <= YoutubeVideoRepository.batchSize; i++)
          _watch('v$i'),
      ],
    );
    final c = container(_Videos(const {}), watched: watched);

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(
      (await c.read(quotaProvider.future)).usageFor(QuotaOperation.videosList),
      2 * QuotaOperation.videosList.cost,
    );
  });

  test('running out of quota stops it, keeping what it fetched, and says '
      'the quota is used up', () async {
    final watched = TakeoutHistory(
      watches: [
        for (var i = 0; i <= YoutubeVideoRepository.batchSize; i++)
          _watch('v$i'),
      ],
    );
    final c = container(
      _Videos({'v0': _short, 'v50': _short}, quotaRunsOut: true),
      watched: watched,
    );

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect((await c.read(quotaProvider.future)).usedUp, isTrue);
    final cache = c.read(videoFormatCacheRepositoryProvider);
    expect((await cache.loadFormats()).keys, ['v0']);
    // Not asked for yet, so not taken to be gone.
    expect(await cache.loadNotFoundIds(), isNot(contains('v50')));
  });

  test("a batch YouTube fails to answer isn't taken to be gone", () async {
    final watched = TakeoutHistory(
      watches: [
        for (var i = 0; i <= 2 * YoutubeVideoRepository.batchSize; i++)
          _watch('v$i'),
      ],
    );
    final c = container(
      _Videos({
        for (final w in watched.watches) w.videoId!: _long,
      }, failingBatch: 1),
      watched: watched,
    );

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    final cache = c.read(videoFormatCacheRepositoryProvider);
    expect(await cache.loadNotFoundIds(), isEmpty);
    expect((await cache.loadFormats()).keys, containsAll(['v0', 'v100']));
  });

  test('says how far along it is', () async {
    final c = container(_Videos(all));
    final seen = <({bool running, int done, int total})>[];
    c.listen(
      videoFormatProgressProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );

    c.read(historyShownProvider.notifier).markShown();
    await _settle();

    expect(seen.any((p) => p.running && p.total == 3), isTrue);
    expect(seen.last, (running: false, done: 3, total: 3));
  });
}
