import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../data/google_auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/sign_in_outcome.dart';
import 'saved_sign_ins.dart';

part 'auth_notifier.g.dart';

/// The viewed channel's sign-in, or null when it has none: a channel counts
/// as signed in only with the sign-in chosen for it.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  /// Counts [signIn] calls, so only the latest reports how it went.
  var _generation = 0;

  @override
  AuthState? build() {
    final channelId = ref.watch(viewedChannelIdProvider);
    if (channelId == null) return null;
    final profile = ref.watch(
      savedSignInsProvider.select((s) => s.value?[channelId]),
    );
    if (profile == null) return null;
    if (!ref.watch(googleAuthRepositoryProvider).hasSession(channelId)) {
      return null;
    }
    return AuthState.fromProfile(profile);
  }

  /// Asks the user to sign in, and saves the sign-in for the channel they
  /// chose, whichever that is. Compares it with [targetChannelId], or else
  /// the channel viewed when sign-in finishes.
  Future<SignInOutcome> signIn({String? targetChannelId}) async {
    final generation = ++_generation;
    final credentials = await ref
        .read(googleAuthRepositoryProvider)
        .requestCredentials();
    if (credentials == null) return const SignInCancelled();

    // Saved even if a newer sign-in started: it's for its own channel.
    final profile = await ref
        .read(savedSignInsProvider.notifier)
        .add(credentials);
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
}

@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider) != null;
}
