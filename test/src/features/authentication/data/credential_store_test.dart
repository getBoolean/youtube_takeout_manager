import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';

AccessCredentials _credentials(String token) => AccessCredentials(
  AccessToken('Bearer', token, DateTime.utc(2026, 9, 26, 12)),
  'refresh-$token',
  const ['scope'],
);

const _a = SignInProfile(channelId: 'UCa', channelTitle: 'Alpha', email: 'a@x');
const _b = SignInProfile(channelId: 'UCb');

void main() {
  late FlutterSecureStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
  });

  test('keeps a sign-in for each channel', () async {
    final store = CredentialStore(storage);
    await store.save(_a, _credentials('ta'));
    await store.save(_b, _credentials('tb'));

    final saved = await CredentialStore(storage).loadAll();

    expect(
      {for (final s in saved) s.profile.channelId: s.profile},
      {'UCa': _a, 'UCb': _b},
    );
    final a = saved.firstWhere((s) => s.profile.channelId == 'UCa');
    expect(a.credentials.accessToken.data, 'ta');
    expect(a.credentials.refreshToken, 'refresh-ta');
    expect(a.credentials.accessToken.expiry, DateTime.utc(2026, 9, 26, 12));
  });

  test('skips other keys and sign-ins it cannot read', () async {
    FlutterSecureStorage.setMockInitialValues({
      'something_else': 'x',
      'google_auth_credentials:UCbroken': 'not json',
    });
    final store = CredentialStore(const FlutterSecureStorage());
    await store.save(_a, _credentials('ta'));

    final saved = await store.loadAll();
    expect(saved.map((s) => s.profile.channelId), ['UCa']);
  });

  test('a refreshed token never brings back a removed sign-in', () async {
    final store = CredentialStore(storage);
    await store.save(_a, _credentials('ta'));
    await store.delete('UCa');

    await store.updateCredentials('UCa', _credentials('refreshed'));

    expect(await store.loadAll(), isEmpty);
  });

  test('a refreshed token replaces the saved one', () async {
    final store = CredentialStore(storage);
    await store.save(_a, _credentials('ta'));

    await store.updateCredentials('UCa', _credentials('refreshed'));

    final saved = (await store.loadAll()).single;
    expect(saved.profile, _a);
    expect(saved.credentials.accessToken.data, 'refreshed');
  });

  test('saves made at the same time all land', () async {
    final store = CredentialStore(storage);
    await Future.wait([
      store.save(_a, _credentials('ta')),
      store.save(_b, _credentials('tb')),
      store.updateCredentials('UCa', _credentials('ta2')),
    ]);

    final saved = {
      for (final s in await store.loadAll())
        s.profile.channelId: s.credentials.accessToken.data,
    };
    expect(saved, {'UCa': 'ta2', 'UCb': 'tb'});
  });

  test(
    'reads and deletes the sign-in saved before there was one per channel',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'google_auth_credentials':
            '{"accessToken":{"type":"Bearer","data":"old",'
            '"expiry":"2026-09-26T12:00:00.000Z"},'
            '"refreshToken":"r","scopes":["s"]}',
      });
      final store = CredentialStore(const FlutterSecureStorage());

      final legacy = await store.loadLegacy();
      expect(legacy?.accessToken.data, 'old');
      expect(legacy?.refreshToken, 'r');
      // Not a channel's sign-in.
      expect(await store.loadAll(), isEmpty);

      await store.deleteLegacy();
      expect(await store.loadLegacy(), isNull);
    },
  );

  test('deleting everything removes every sign-in, even unreadable and '
      'legacy ones, and nothing else', () async {
    FlutterSecureStorage.setMockInitialValues({
      'something_else': 'x',
      'google_auth_credentials:UCbroken': 'not json',
      CredentialStore.legacyKey: 'old',
    });
    final store = CredentialStore(const FlutterSecureStorage());
    await store.save(_a, _credentials('ta'));

    await store.deleteAll();

    expect(await const FlutterSecureStorage().readAll(), {
      'something_else': 'x',
    });
  });
}
