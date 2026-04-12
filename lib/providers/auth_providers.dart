import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/auth_state.dart';
import '../services/google_auth_service.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  final _authService = GoogleAuthService();

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
}

@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider) != null;
}
