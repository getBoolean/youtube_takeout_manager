import 'dart:async';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import '../data/credential_store.dart';
import '../data/google_auth_repository.dart';
import '../domain/sign_in_profile.dart';

part 'saved_sign_ins.g.dart';

/// Whether Google sign-in has a client configured. Overridable in tests.
@Riverpod(keepAlive: true)
bool oauthConfigured(Ref ref) => isOAuthConfigured;

/// Titles of the channels with a saved sign-in, by channel ID, from the
/// YouTube API at sign-in. Names takeout channels their saved data gives no
/// title, e.g. data saved before channel lists were kept.
@Riverpod(keepAlive: true)
Map<String, String> signedInChannelTitles(Ref ref) => {
  for (final profile
      in (ref.watch(savedSignInsProvider).value ?? const {}).values)
    profile.channelId: ?profile.channelTitle,
};

/// A sign-in that stopped working and was removed. Compared by identity, so
/// each loss is reported even if the same channel's is lost twice.
class LostSignIn {
  final SignInProfile profile;

  LostSignIn(this.profile);
}

/// The last sign-in that stopped working, for the UI to report.
@Riverpod(keepAlive: true)
class LostSignInNotifier extends _$LostSignInNotifier {
  @override
  LostSignIn? build() => null;

  void report(SignInProfile profile) => state = LostSignIn(profile);
}

/// Every saved sign-in, by the YouTube channel chosen when signing in, each
/// with a session ready to use.
@Riverpod(keepAlive: true)
class SavedSignIns extends _$SavedSignIns {
  static const _lookupTimeout = Duration(seconds: 15);

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
    if (await _moveLegacySignIn() case final profile?) {
      profiles[profile.channelId] = profile;
    }
    return profiles;
  }

  /// Saves [credentials] for the channel they were signed in with, and
  /// returns who that is. Null, saving nothing, when the account has no
  /// YouTube channel.
  Future<SignInProfile?> add(AccessCredentials credentials) async {
    final client = _repository.clientFor(credentials);
    final SignInProfile? profile;
    try {
      profile = await _profileOf(client);
    } finally {
      client.close();
    }
    if (profile == null) return null;
    await _store.save(profile, credentials);
    _addSession(profile.channelId, credentials);
    final current = await future;
    state = AsyncData({...current, profile.channelId: profile});
    return profile;
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

  /// Removes [channelId]'s sign-in because it stopped working (access
  /// revoked, account deleted), and reports it.
  Future<void> signInFailed(String channelId) async {
    final profile = (await future)[channelId];
    await remove(channelId);
    if (profile != null) {
      ref.read(lostSignInProvider.notifier).report(profile);
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

  /// Looks up the channel [client] is signed in with, and its Google
  /// account. Null when the account has no channel.
  Future<SignInProfile?> _profileOf(http.Client client) async {
    final channel = await ref
        .read(youtubeChannelRepositoryProvider)
        .fetchMyChannel(client);
    await ref
        .read(quotaProvider.notifier)
        .recordUsage(QuotaOperation.channelsList);
    if (channel == null) return null;
    final user = await _repository.fetchUserInfo(client);
    return SignInProfile(
      channelId: channel.id,
      channelTitle: channel.title,
      channelHandle: channel.handle,
      channelThumbnailUrl: channel.thumbnailUrl,
      displayName: user['name'] as String?,
      email: user['email'] as String?,
      photoUrl: user['picture'] as String?,
    );
  }

  /// Moves the sign-in saved before there was one per channel to the
  /// channel it's for. Keeps it to try again if that can't be looked up,
  /// e.g. offline; deletes it if Google refuses it or its account has no
  /// channel.
  Future<SignInProfile?> _moveLegacySignIn() async {
    final credentials = await _store.loadLegacy();
    if (credentials == null) return null;
    if (!_repository.isUsable(credentials)) {
      await _store.deleteLegacy();
      return null;
    }

    final client = _repository.clientFor(credentials);
    try {
      final profile = await _profileOf(client).timeout(_lookupTimeout);
      if (profile != null) {
        await _store.save(profile, credentials);
        _addSession(profile.channelId, credentials);
      }
      await _store.deleteLegacy();
      return profile;
    } on Object catch (e) {
      if (isSignInFailure(e)) await _store.deleteLegacy();
      return null;
    } finally {
      client.close();
    }
  }
}
