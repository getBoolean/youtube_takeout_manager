import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../data/credential_store.dart';
import '../data/google_auth_repository.dart';
import '../data/oauth_client_repository.dart';
import '../domain/sign_in_outcome.dart';
import '../domain/sign_in_profile.dart';
import 'lost_sign_in.dart';
import 'saved_sign_ins.dart';

part 'sign_in_service.g.dart';

/// Signs channels in and out, looking each sign-in's channel up on YouTube,
/// and drops sign-ins that stop working. Nothing depends on it, so it can
/// use any provider.
@Riverpod(keepAlive: true)
class SignInService extends _$SignInService {
  static const _lookupTimeout = Duration(seconds: 15);

  /// Counts [signIn] calls, so only the latest reports how it went.
  var _generation = 0;

  GoogleAuthRepository get _repository =>
      ref.read(googleAuthRepositoryProvider);

  @override
  void build() {}

  /// Asks the user to sign in, and saves the sign-in for the channel they
  /// chose, whichever that is. Compares it with [targetChannelId], or else
  /// the channel viewed when sign-in finishes.
  Future<SignInOutcome> signIn({String? targetChannelId}) async {
    final generation = ++_generation;
    // So a client that was just set up signs in.
    await ref.read(oauthClientProvider.future);
    final credentials = await _repository.requestCredentials();
    if (credentials == null) return const SignInCancelled();

    // Saved even if a newer sign-in started: it's for its own channel.
    final profile = await add(credentials);
    if (generation != _generation) return const SignInCancelled();
    if (profile == null) return const SignInNoChannel();

    final target = targetChannelId ?? ref.read(viewedChannelIdProvider);
    if (target == null || target == profile.channelId) {
      return SignedIn(profile);
    }
    return SignedInOtherChannel(profile, targetChannelId: target);
  }

  /// Signs [channelId] out, or else the viewed channel. Other channels stay
  /// signed in.
  Future<void> signOut({String? channelId}) async {
    channelId ??= ref.read(viewedChannelIdProvider);
    if (channelId == null) return;
    await ref
        .read(savedSignInsProvider.notifier)
        .remove(channelId, revoke: true);
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
    await ref.read(savedSignInsProvider.notifier).save(profile, credentials);
    return profile;
  }

  /// Removes [channelId]'s sign-in because it stopped working (access
  /// revoked, account deleted), and reports it.
  Future<void> signInFailed(String channelId) async {
    final profile = (await ref.read(savedSignInsProvider.future))[channelId];
    await ref.read(savedSignInsProvider.notifier).remove(channelId);
    if (profile != null) {
      ref.read(lostSignInProvider.notifier).report(profile);
    }
  }

  /// Moves the sign-in saved before there was one per channel to the
  /// channel it's for. Keeps it to try again if that can't be looked up,
  /// e.g. offline; deletes it if Google refuses it or its account has no
  /// channel.
  Future<void> moveLegacySignIn() async {
    // Without a client, sessions couldn't refresh and would look revoked.
    if (await ref.read(oauthClientProvider.future) == null) return;
    // After the saved sign-ins, so this one joins them.
    await ref.read(savedSignInsProvider.future);
    final store = ref.read(credentialStoreProvider);
    final credentials = await store.loadLegacy();
    if (credentials == null) return;
    if (!_repository.isUsable(credentials)) {
      await store.deleteLegacy();
      return;
    }

    final client = _repository.clientFor(credentials);
    try {
      final profile = await _profileOf(client).timeout(_lookupTimeout);
      if (profile != null) {
        await ref
            .read(savedSignInsProvider.notifier)
            .save(profile, credentials);
      }
      await store.deleteLegacy();
    } on Object catch (e) {
      if (isSignInFailure(e)) await store.deleteLegacy();
    } finally {
      client.close();
    }
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
}

/// Moves the sign-in saved before there was one per channel, once, at
/// start-up.
@Riverpod(keepAlive: true)
Future<void> legacySignInMigration(Ref ref) =>
    ref.read(signInServiceProvider.notifier).moveLegacySignIn();
