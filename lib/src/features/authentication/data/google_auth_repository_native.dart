import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import '../model/auth_state.dart';
import 'google_auth_repository.dart';

GoogleAuthRepository createGoogleAuthRepository() =>
    NativeGoogleAuthRepository();

class NativeGoogleAuthRepository extends GoogleAuthRepository {
  auth_io.AutoRefreshingAuthClient? _client;

  @override
  http.Client? get authClient => _client;

  @override
  Future<AuthState?> signIn() async {
    try {
      final clientId = auth_io.ClientId(googleClientId, googleClientSecret);

      final client = await auth_io.clientViaUserConsent(
        clientId,
        scopes,
        _openBrowser,
      );

      _client = client;
      client.credentialUpdates.listen(persistCredentials);
      await persistCredentials(client.credentials);

      final userInfo = await fetchUserInfo(client);
      return buildAuthState(client.credentials.accessToken.data, userInfo);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    _client?.close();
    _client = null;
    await clearPersistedCredentials();
  }

  @override
  http.Client getAuthenticatedClient(String accessToken) {
    if (_client != null) return NonClosingClient(_client!);

    final credentials = auth_io.AccessCredentials(
      auth_io.AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      scopes,
    );
    return auth_io.authenticatedClient(http.Client(), credentials);
  }

  @override
  Future<AuthState?> tryRestoreSession() async {
    final credentials = await loadPersistedCredentials();
    if (credentials == null || credentials.refreshToken == null) return null;

    try {
      final clientId = auth_io.ClientId(googleClientId, googleClientSecret);
      final client = auth_io.autoRefreshingClient(
        clientId,
        credentials,
        http.Client(),
      );

      _client = client;
      client.credentialUpdates.listen(persistCredentials);

      final userInfo = await fetchUserInfo(client);
      return buildAuthState(client.credentials.accessToken.data, userInfo);
    } on Exception {
      await clearPersistedCredentials();
      return null;
    }
  }

  void _openBrowser(String url) {
    launchUrl(Uri.parse(url));
  }
}
