import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_outcome.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

/// Credentials whose access token names the channel they're for.
AccessCredentials _credentials(String token) => AccessCredentials(
  AccessToken('Bearer', token, DateTime.utc(2030)),
  'refresh',
  scopes,
);

Map<String, Object?> _credentialsJson(
  String token, {
  bool refreshable = true,
}) => {
  'accessToken': {
    'type': 'Bearer',
    'data': token,
    'expiry': DateTime.utc(2030).toIso8601String(),
  },
  'refreshToken': refreshable ? 'refresh' : null,
  'scopes': scopes,
};

String _saved(String channelId, {bool refreshable = true}) => jsonEncode({
  'profile': SignInProfile(channelId: channelId).toMap(),
  'credentials': _credentialsJson(channelId, refreshable: refreshable),
});

String _legacy(String token) => jsonEncode(_credentialsJson(token));

/// A client that says which token it was made for.
class _TokenClient extends http.BaseClient {
  final String token;

  _TokenClient(this.token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();
}

class _FakeAuthRepository extends GoogleAuthRepository {
  AccessCredentials? next;
  final sessions = <String>{};
  final closed = <(String, bool)>[];

  @override
  Future<AccessCredentials?> requestCredentials() async => next;

  @override
  bool isUsable(AccessCredentials credentials) =>
      credentials.refreshToken != null;

  @override
  http.Client clientFor(AccessCredentials credentials) =>
      _TokenClient(credentials.accessToken.data);

  @override
  void addSession(
    String channelId,
    AccessCredentials credentials, {
    required void Function(AccessCredentials credentials) onRefreshed,
  }) => sessions.add(channelId);

  @override
  bool hasSession(String channelId) => sessions.contains(channelId);

  @override
  http.Client getAuthenticatedClient(String channelId) =>
      _TokenClient(channelId);

  @override
  Future<void> closeSession(String channelId, {bool revoke = false}) async {
    sessions.remove(channelId);
    closed.add((channelId, revoke));
  }

  @override
  Future<Map<String, dynamic>> fetchUserInfo(http.Client client) async => {
    'email': '${(client as _TokenClient).token}@example.com',
  };
}

/// Token "UCx" is channel UCx; "none" has no channel; "offline" and
/// "refused" fail.
class _FakeChannels extends YoutubeChannelRepository {
  @override
  Future<({String id, String? title, String? handle, String? thumbnailUrl})?>
  fetchMyChannel(http.Client authClient) async {
    final token = (authClient as _TokenClient).token;
    return switch (token) {
      'none' => null,
      'offline' => throw const SocketException('offline'),
      'refused' => throw ServerRequestFailedException(
        'invalid_grant',
        statusCode: 400,
        responseContent: {'error': 'invalid_grant'},
      ),
      _ => (id: token, title: 'Title $token', handle: null, thumbnailUrl: null),
    };
  }
}

class _Viewed extends Notifier<String?> {
  @override
  String? build() => 'UCa';

  void set(String? channelId) => state = channelId;
}

final _viewed = NotifierProvider<_Viewed, String?>(_Viewed.new);

void main() {
  late _FakeAuthRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    repository = _FakeAuthRepository();
  });

  ProviderContainer container({bool configured = true}) {
    final c = ProviderContainer(
      overrides: [
        oauthConfiguredProvider.overrideWithValue(configured),
        googleAuthRepositoryProvider.overrideWithValue(repository),
        youtubeChannelRepositoryProvider.overrideWithValue(_FakeChannels()),
        viewedChannelIdProvider.overrideWith((ref) => ref.watch(_viewed)),
      ],
    );
    addTearDown(c.dispose);
    c
      ..listen(authProvider, (_, _) {})
      ..listen(readSessionChannelIdProvider, (_, _) {});
    return c;
  }

  CredentialStore store() => CredentialStore(const FlutterSecureStorage());

  Future<Set<String>> storedChannels() async => {
    for (final s in await store().loadAll()) s.profile.channelId,
  };

  test("restores saved sign-ins and drops ones it can't use", () async {
    FlutterSecureStorage.setMockInitialValues({
      'google_auth_credentials:UCa': _saved('UCa'),
      'google_auth_credentials:UCb': _saved('UCb', refreshable: false),
    });
    final c = container();

    expect((await c.read(savedSignInsProvider.future)).keys, ['UCa']);
    expect(repository.sessions, {'UCa'});
    expect(await storedChannels(), {'UCa'});
  });

  test('the viewed channel is signed in only with its own sign-in', () async {
    FlutterSecureStorage.setMockInitialValues({
      'google_auth_credentials:UCa': _saved('UCa'),
    });
    final c = container();
    await c.read(savedSignInsProvider.future);

    expect(c.read(authProvider)?.channelId, 'UCa');
    c.read(_viewed.notifier).set('UCb');
    expect(c.read(authProvider), isNull);
    c.read(_viewed.notifier).set('UCa');
    expect(c.read(authProvider)?.channelId, 'UCa');
  });

  test('signing in with the viewed channel signs it in', () async {
    final c = container();
    await c.read(savedSignInsProvider.future);
    repository.next = _credentials('UCa');

    final outcome = await c.read(authProvider.notifier).signIn();

    expect(outcome, isA<SignedIn>());
    expect(c.read(authProvider)?.channelId, 'UCa');
    expect(c.read(authProvider)?.email, 'UCa@example.com');
    expect(await storedChannels(), {'UCa'});
    // Looking up the channel costs a unit.
    expect((await c.read(quotaProvider.future)).unitsUsed, 1);
  });

  test('signing in with another channel saves it for that channel and warns, '
      'leaving the viewed one signed out', () async {
    final c = container();
    await c.read(savedSignInsProvider.future);
    repository.next = _credentials('UCb');

    final outcome = await c.read(authProvider.notifier).signIn();

    expect(
      outcome,
      isA<SignedInOtherChannel>()
          .having((o) => o.profile.channelId, 'chosen', 'UCb')
          .having((o) => o.viewedChannelId, 'viewed', 'UCa'),
    );
    expect(c.read(authProvider), isNull);
    expect(await storedChannels(), {'UCb'});

    // Used when its own channel is viewed.
    c.read(_viewed.notifier).set('UCb');
    expect(c.read(authProvider)?.channelId, 'UCb');
  });

  test('an account without a YouTube channel saves nothing', () async {
    final c = container();
    await c.read(savedSignInsProvider.future);
    repository.next = _credentials('none');

    expect(
      await c.read(authProvider.notifier).signIn(),
      isA<SignInNoChannel>(),
    );
    expect(await storedChannels(), isEmpty);
    expect(repository.sessions, isEmpty);
  });

  test('cancelling saves nothing', () async {
    final c = container();
    await c.read(savedSignInsProvider.future);

    expect(
      await c.read(authProvider.notifier).signIn(),
      isA<SignInCancelled>(),
    );
    expect(await storedChannels(), isEmpty);
  });

  test("signing out removes only the viewed channel's sign-in", () async {
    FlutterSecureStorage.setMockInitialValues({
      'google_auth_credentials:UCa': _saved('UCa'),
      'google_auth_credentials:UCb': _saved('UCb'),
    });
    final c = container();
    await c.read(savedSignInsProvider.future);

    await c.read(authProvider.notifier).signOut();

    expect(c.read(authProvider), isNull);
    expect(c.read(savedSignInsProvider).value?.keys, ['UCb']);
    expect(await storedChannels(), {'UCb'});
    expect(repository.closed, [('UCa', true)]);
  });

  test('a sign-in that stops working is removed and reported', () async {
    FlutterSecureStorage.setMockInitialValues({
      'google_auth_credentials:UCa': _saved('UCa'),
    });
    final c = container();
    c.listen(lostSignInProvider, (_, _) {});
    await c.read(savedSignInsProvider.future);

    await c.read(savedSignInsProvider.notifier).signInFailed('UCa');

    expect(c.read(authProvider), isNull);
    expect(await storedChannels(), isEmpty);
    expect(c.read(lostSignInProvider)?.profile.channelId, 'UCa');
  });

  group('reads', () {
    test("use the viewed channel's sign-in, else any other", () async {
      FlutterSecureStorage.setMockInitialValues({
        'google_auth_credentials:UCa': _saved('UCa'),
        'google_auth_credentials:UCb': _saved('UCb'),
      });
      final c = container();
      await c.read(savedSignInsProvider.future);

      c.read(_viewed.notifier).set('UCb');
      expect(c.read(readSessionChannelIdProvider), 'UCb');
      c.read(_viewed.notifier).set('UCsignedOut');
      expect(c.read(readSessionChannelIdProvider), isIn(['UCa', 'UCb']));
    });

    test('have no sign-in to use when there are none', () async {
      final c = container();
      await c.read(savedSignInsProvider.future);
      expect(c.read(readSessionChannelIdProvider), isNull);
    });
  });

  group('the sign-in saved before there was one per channel', () {
    test('moves to its channel', () async {
      FlutterSecureStorage.setMockInitialValues({
        'google_auth_credentials': _legacy('UCa'),
      });
      final c = container();

      expect((await c.read(savedSignInsProvider.future)).keys, ['UCa']);
      expect(c.read(authProvider)?.channelId, 'UCa');
      expect(await storedChannels(), {'UCa'});
      expect(await store().loadLegacy(), isNull);
      expect((await c.read(quotaProvider.future)).unitsUsed, 1);
    });

    test('is kept to try again when offline', () async {
      FlutterSecureStorage.setMockInitialValues({
        'google_auth_credentials': _legacy('offline'),
      });
      final c = container();

      expect(await c.read(savedSignInsProvider.future), isEmpty);
      expect(await store().loadLegacy(), isNotNull);
    });

    test('is deleted when Google refuses it', () async {
      FlutterSecureStorage.setMockInitialValues({
        'google_auth_credentials': _legacy('refused'),
      });
      final c = container();

      expect(await c.read(savedSignInsProvider.future), isEmpty);
      expect(await store().loadLegacy(), isNull);
    });

    test('is deleted when its account has no channel', () async {
      FlutterSecureStorage.setMockInitialValues({
        'google_auth_credentials': _legacy('none'),
      });
      final c = container();

      expect(await c.read(savedSignInsProvider.future), isEmpty);
      expect(await store().loadLegacy(), isNull);
    });
  });

  test('without sign-in configured, saved sign-ins are left alone', () async {
    FlutterSecureStorage.setMockInitialValues({
      'google_auth_credentials:UCa': _saved('UCa'),
      'google_auth_credentials': _legacy('UCa'),
    });
    final c = container(configured: false);

    expect(await c.read(savedSignInsProvider.future), isEmpty);
    expect(repository.sessions, isEmpty);
    expect(await storedChannels(), {'UCa'});
    expect(await store().loadLegacy(), isNotNull);
  });
}
