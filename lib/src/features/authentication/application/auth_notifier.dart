import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../data/google_auth_repository.dart';
import '../domain/auth_state.dart';
import 'saved_sign_ins.dart';

part 'auth_notifier.g.dart';

/// The viewed channel's sign-in, or null when it has none: a channel counts
/// as signed in only with the sign-in chosen for it. Signing in and out is
/// `SignInService`'s.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
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
}

@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider) != null;
}
