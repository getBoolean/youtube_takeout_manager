import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';

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

class _Channels extends YoutubeChannelRepository {
  final bool signInFails;

  /// Channels YouTube doesn't have.
  final Set<String> missing;

  /// How many requests fail, as when offline, before they work.
  int failures;

  /// The channels each request asked for.
  final requests = <List<String>>[];

  _Channels({
    this.signInFails = false,
    this.missing = const {},
    this.failures = 0,
  });

  @override
  Future<Map<String, String>> fetchChannelThumbnails(
    http.Client authClient,
    Set<String> channelIds,
  ) async {
    requests.add(channelIds.toList());
    if (failures > 0) {
      failures--;
      throw http.ClientException('offline');
    }
    if (signInFails) {
      throw ServerRequestFailedException(
        'invalid_grant',
        statusCode: 400,
        responseContent: {'error': 'invalid_grant'},
      );
    }
    return {
      for (final id in channelIds)
        if (!missing.contains(id)) id: 'https://yt3.example/$id',
    };
  }
}

/// The channels the viewed channel interacted with, as the channel list
/// shows them.
class _Shown extends Notifier<List<Channel>> {
  @override
  List<Channel> build() => const [];

  void set(Iterable<String> ids) => state = [
    for (final id in ids)
      Channel(channelId: id, commentCount: 1, liveChatCount: 0),
  ];
}

final _shown = NotifierProvider<_Shown, List<Channel>>(_Shown.new);

class _SignIns extends SignInService {
  final failed = <String>[];

  @override
  void build() {}

  @override
  Future<void> signInFailed(String channelId) async => failed.add(channelId);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer container({
    required _Clients clients,
    required _SignIns signIns,
    String? session = 'UCother',
    bool signInFails = false,
    _Channels? channels,
  }) {
    final c = ProviderContainer(
      overrides: [
        readSessionChannelIdProvider.overrideWithValue(session),
        googleAuthRepositoryProvider.overrideWithValue(clients),
        youtubeChannelRepositoryProvider.overrideWithValue(
          channels ?? _Channels(signInFails: signInFails),
        ),
        signInServiceProvider.overrideWith(() => signIns),
        channelsProvider.overrideWith((ref) => ref.watch(_shown)),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(channelThumbnailsProvider, (_, _) {})
      ..listen(channelThumbnailFetcherProvider, (_, _) {});
    return c;
  }

  /// Queues [channelIds] and fetches them without waiting for a batch.
  Future<void> fetch(ProviderContainer c, Set<String> channelIds) {
    final fetcher = c.read(channelThumbnailFetcherProvider.notifier)
      ..queueChannelIds(channelIds);
    return fetcher.flushQueue();
  }

  test('loads avatars with whichever sign-in is available', () async {
    final clients = _Clients();
    final c = container(clients: clients, signIns: _SignIns());

    await fetch(c, {'UCa'});

    expect(clients.used, ['UCother']);
    expect(c.read(channelThumbnailsProvider).value, {
      'UCa': 'https://yt3.example/UCa',
    });
  });

  test('keeps saved pictures and saves fetched ones with them', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.cached_channel_thumbnails': '{"UCold":"https://saved/UCold"}',
    });
    final c = container(clients: _Clients(), signIns: _SignIns());
    await pumpEventQueue();

    await fetch(c, {'UCold', 'UCa'});

    final pictures = {
      'UCold': 'https://saved/UCold',
      'UCa': 'https://yt3.example/UCa',
    };
    expect(c.read(channelThumbnailsProvider).value, pictures);

    // A fresh start loads both from storage.
    final reloaded = ProviderContainer();
    addTearDown(reloaded.dispose);
    expect(await reloaded.read(channelThumbnailsProvider.future), pictures);
  });

  test('loads nothing without a sign-in', () async {
    final clients = _Clients();
    final c = container(clients: clients, signIns: _SignIns(), session: null);

    await fetch(c, {'UCa'});

    expect(clients.used, isEmpty);
  });

  test('reports a sign-in that stops working', () async {
    final signIns = _SignIns();
    final c = container(
      clients: _Clients(),
      signIns: signIns,
      signInFails: true,
    );

    await fetch(c, {'UCa'});

    expect(signIns.failed, ['UCother']);
    expect(c.read(channelThumbnailsProvider).value, isEmpty);
  });

  test('fetches pictures once a batch of new channels shows', () async {
    final clients = _Clients();
    final c = container(clients: clients, signIns: _SignIns());

    c.read(_shown.notifier).set([
      for (var i = 0; i < thumbnailBatchSize - 1; i++) 'UC$i',
    ]);
    await pumpEventQueue();
    expect(clients.used, isEmpty);

    c.read(_shown.notifier).set([
      for (var i = 0; i < thumbnailBatchSize; i++) 'UC$i',
    ]);
    await pumpEventQueue();
    expect(clients.used, ['UCother']);
    expect(
      c.read(channelThumbnailsProvider).value,
      hasLength(thumbnailBatchSize),
    );
  });

  test('fetches the rest once video titles are done', () async {
    final clients = _Clients();
    final c = container(clients: clients, signIns: _SignIns());
    final progress = c.read(videoFetchProgressProvider.notifier)..start(1);

    c.read(_shown.notifier).set(['UCa']);
    await pumpEventQueue();
    expect(clients.used, isEmpty);

    progress.complete();
    await pumpEventQueue();
    expect(c.read(channelThumbnailsProvider).value, {
      'UCa': 'https://yt3.example/UCa',
    });
  });

  group('fetching a whole list, as history does', () {
    test('asks for 50 channels a request, in the order given, counting '
        'each request', () async {
      final channels = _Channels();
      final c = container(
        clients: _Clients(),
        signIns: _SignIns(),
        channels: channels,
      );
      final ids = [for (var i = 0; i < 120; i++) 'UC$i'];

      await c.read(channelThumbnailFetcherProvider.notifier).fetchNow(ids);

      expect([for (final r in channels.requests) r.length], [50, 50, 20]);
      expect(channels.requests.first.first, 'UC0');
      expect(c.read(channelThumbnailsProvider).value, hasLength(120));
      final quota = await c.read(quotaProvider.future);
      expect(quota.usageFor(QuotaOperation.channelsList), 3);
    });

    test("asks only once for channels YouTube doesn't have, even after a "
        'restart', () async {
      final channels = _Channels(missing: {'UCgone'});
      final c = container(
        clients: _Clients(),
        signIns: _SignIns(),
        channels: channels,
      );
      final fetcher = c.read(channelThumbnailFetcherProvider.notifier);

      await fetcher.fetchNow(['UCa', 'UCgone']);
      await fetcher.fetchNow(['UCgone']);
      expect(channels.requests, hasLength(1));

      final restarted = container(
        clients: _Clients(),
        signIns: _SignIns(),
        channels: channels,
      );
      await restarted.read(channelThumbnailFetcherProvider.notifier).fetchNow([
        'UCgone',
      ]);
      expect(channels.requests, hasLength(1));
    });

    test('asks again later for channels a failed request was for', () async {
      final channels = _Channels(failures: 1);
      final c = container(
        clients: _Clients(),
        signIns: _SignIns(),
        channels: channels,
      );
      final fetcher = c.read(channelThumbnailFetcherProvider.notifier);

      await fetcher.fetchNow(['UCa']);
      expect(c.read(channelThumbnailsProvider).value, isEmpty);

      await fetcher.fetchNow(['UCa']);
      expect(channels.requests, hasLength(2));
      expect(c.read(channelThumbnailsProvider).value, contains('UCa'));
    });
  });
}
