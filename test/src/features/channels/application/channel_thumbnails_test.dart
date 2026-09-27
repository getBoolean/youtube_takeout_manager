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

  _Channels({this.signInFails = false});

  @override
  Future<Map<String, String>> fetchChannelThumbnails(
    http.Client authClient,
    Set<String> channelIds,
  ) async {
    if (signInFails) {
      throw ServerRequestFailedException(
        'invalid_grant',
        statusCode: 400,
        responseContent: {'error': 'invalid_grant'},
      );
    }
    return {for (final id in channelIds) id: 'https://yt3.example/$id'};
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
  }) {
    final c = ProviderContainer(
      overrides: [
        readSessionChannelIdProvider.overrideWithValue(session),
        googleAuthRepositoryProvider.overrideWithValue(clients),
        youtubeChannelRepositoryProvider.overrideWithValue(
          _Channels(signInFails: signInFails),
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
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('cached_channel_thumbnails'),
      '{"UCold":"https://saved/UCold","UCa":"https://yt3.example/UCa"}',
    );
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

  test('fetches pictures once 10 new channels show', () async {
    final clients = _Clients();
    final c = container(clients: clients, signIns: _SignIns());

    c.read(_shown.notifier).set([for (var i = 0; i < 9; i++) 'UC$i']);
    await pumpEventQueue();
    expect(clients.used, isEmpty);

    c.read(_shown.notifier).set([for (var i = 0; i < 10; i++) 'UC$i']);
    await pumpEventQueue();
    expect(clients.used, ['UCother']);
    expect(c.read(channelThumbnailsProvider).value, hasLength(10));
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
}
