import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/auth_state.dart';
import '../services/google_auth_service.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  final _authService = GoogleAuthService.instance;

  @override
  AuthState? build() => null;

  Future<void> signIn() async {
    final authState = await _authService.signIn();
    if (authState != null) {
      state = authState;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  /// Attempt to restore a previous session from persisted credentials.
  Future<void> tryRestoreSession() async {
    final authState = await _authService.tryRestoreSession();
    if (authState != null) {
      state = authState;
    }
  }
}

@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider) != null;
}
