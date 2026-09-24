import 'package:googleapis_auth/auth_browser.dart';
import 'package:http/http.dart' as http;

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import '../domain/auth_state.dart';
import 'google_auth_service.dart';

GoogleAuthService createGoogleAuthService() => WebGoogleAuthService();

class WebGoogleAuthService extends GoogleAuthService {
  http.Client? _client;
  String? _accessToken;

  @override
  http.Client? get authClient => _client;

  @override
  Future<AuthState?> signIn() async {
    try {
      final credentials = await requestAccessCredentials(
        clientId: googleWebClientId,
        scopes: scopes,
      );

      final client = authenticatedClient(http.Client(), credentials);
      _client = client;
      _accessToken = credentials.accessToken.data;
      await persistCredentials(credentials);

      final userInfo = await fetchUserInfo(client);
      return buildAuthState(credentials.accessToken.data, userInfo);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    final token = _accessToken;
    if (token != null) {
      try {
        await revokeConsent(token);
      } on Exception {
        // Best-effort revocation.
      }
    }
    _client?.close();
    _client = null;
    _accessToken = null;
    await clearPersistedCredentials();
  }

  @override
  http.Client getAuthenticatedClient(String accessToken) {
    if (_client != null) return NonClosingClient(_client!);

    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      scopes,
    );
    return authenticatedClient(http.Client(), credentials);
  }

  @override
  Future<AuthState?> tryRestoreSession() async {
    final credentials = await loadPersistedCredentials();
    if (credentials == null) return null;

    // On web there is no refresh token. Only restore if the access token is
    // still valid (with a 5-minute buffer).
    final buffer = const Duration(minutes: 5);
    if (credentials.accessToken.expiry.isBefore(
      DateTime.now().toUtc().add(buffer),
    )) {
      await clearPersistedCredentials();
      return null;
    }

    final client = authenticatedClient(http.Client(), credentials);
    _client = client;
    _accessToken = credentials.accessToken.data;

    final userInfo = await fetchUserInfo(client);
    return buildAuthState(credentials.accessToken.data, userInfo);
  }
}
