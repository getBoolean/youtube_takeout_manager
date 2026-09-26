import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';

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
        responseContent: null,
      );
    }
    return {for (final id in channelIds) id: 'https://yt3.example/$id'};
  }
}

class _SignIns extends SavedSignIns {
  final failed = <String>[];

  @override
  Future<Map<String, SignInProfile>> build() async => const {};

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
        savedSignInsProvider.overrideWith(() => signIns),
      ],
    );
    addTearDown(c.dispose);
    c.listen(channelThumbnailsProvider, (_, _) {});
    return c;
  }

  test('loads avatars with whichever sign-in is available', () async {
    final clients = _Clients();
    final c = container(clients: clients, signIns: _SignIns());

    await c.read(channelThumbnailsProvider.notifier).fetchThumbnails({'UCa'});

    expect(clients.used, ['UCother']);
    expect(c.read(channelThumbnailsProvider), {
      'UCa': 'https://yt3.example/UCa',
    });
  });

  test('loads nothing without a sign-in', () async {
    final clients = _Clients();
    final c = container(clients: clients, signIns: _SignIns(), session: null);

    await c.read(channelThumbnailsProvider.notifier).fetchThumbnails({'UCa'});

    expect(clients.used, isEmpty);
  });

  test('reports a sign-in that stops working', () async {
    final signIns = _SignIns();
    final c = container(
      clients: _Clients(),
      signIns: signIns,
      signInFails: true,
    );

    await c.read(channelThumbnailsProvider.notifier).fetchThumbnails({'UCa'});

    expect(signIns.failed, ['UCother']);
    expect(c.read(channelThumbnailsProvider), isEmpty);
  });
}
