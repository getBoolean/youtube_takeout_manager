import 'dart:async';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/credential_store.dart';
import '../data/google_auth_repository.dart';
import '../domain/sign_in_profile.dart';
import 'oauth_configured.dart';

part 'saved_sign_ins.g.dart';

/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use. Looking sign-ins up and dropping ones that
/// stop working is `SignInService`'s.
@Riverpod(keepAlive: true)
class SavedSignIns extends _$SavedSignIns {
  CredentialStore get _store => ref.read(credentialStoreProvider);
  GoogleAuthRepository get _repository =>
      ref.read(googleAuthRepositoryProvider);

  @override
  Future<Map<String, SignInProfile>> build() async {
    // Without a client, sessions couldn't refresh and would look revoked, so
    // leave saved sign-ins alone for a build that has one.
    if (!ref.watch(oauthConfiguredProvider)) return const {};
    final store = ref.watch(credentialStoreProvider);
    final repository = ref.watch(googleAuthRepositoryProvider);

    final profiles = <String, SignInProfile>{};
    for (final (:profile, :credentials) in await store.loadAll()) {
      if (!repository.isUsable(credentials)) {
        await store.delete(profile.channelId);
        continue;
      }
      _addSession(profile.channelId, credentials);
      profiles[profile.channelId] = profile;
    }
    return profiles;
  }

  /// Saves [credentials] as [profile]'s channel's sign-in, with a session
  /// ready to use.
  Future<void> save(
    SignInProfile profile,
    AccessCredentials credentials,
  ) async {
    await _store.save(profile, credentials);
    _addSession(profile.channelId, credentials);
    final current = await future;
    state = AsyncData({...current, profile.channelId: profile});
  }

  /// Removes [channelId]'s sign-in. [revoke] also revokes its token where
  /// the platform can.
  Future<void> remove(String channelId, {bool revoke = false}) async {
    await _repository.closeSession(channelId, revoke: revoke);
    await _store.delete(channelId);
    final current = await future;
    state = AsyncData({...current}..remove(channelId));
  }

  /// Removes the sign-ins of [channelIds], revoking them where the platform
  /// can.
  Future<void> removeAll(Set<String> channelIds) async {
    for (final channelId in channelIds) {
      await remove(channelId, revoke: true);
    }
  }

  void _addSession(String channelId, AccessCredentials credentials) {
    final store = _store;
    _repository.addSession(
      channelId,
      credentials,
      onRefreshed: (refreshed) =>
          unawaited(store.updateCredentials(channelId, refreshed)),
    );
  }
}
