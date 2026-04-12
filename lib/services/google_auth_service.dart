import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/oauth_config.dart';
import '../models/auth_state.dart';

const _scopes = [
  'https://www.googleapis.com/auth/youtube.force-ssl',
  'openid',
  'email',
  'profile',
];

const _credentialsKey = 'google_auth_credentials';

/// Service for Google OAuth2 authentication.
///
/// Uses `googleapis_auth` with a browser-based consent flow that works on
/// desktop platforms (Windows/macOS/Linux). A local HTTP server captures the
/// OAuth redirect after the user consents in their browser.
class GoogleAuthService {
  GoogleAuthService._();
  static final instance = GoogleAuthService._();

  auth_io.AutoRefreshingAuthClient? _authClient;

  /// Triggers the interactive sign-in flow via the user's default browser.
  /// Returns an [AuthState] on success, or null if cancelled/failed.
  Future<AuthState?> signIn() async {
    try {
      final clientId = auth_io.ClientId(googleClientId, googleClientSecret);

      final client = await auth_io.clientViaUserConsent(
        clientId,
        _scopes,
        _openBrowser,
      );

      _authClient = client;
      client.credentialUpdates.listen(_persistCredentials);
      await _persistCredentials(client.credentials);

      final userInfo = await _fetchUserInfo(client);

      return AuthState(
        accessToken: client.credentials.accessToken.data,
        displayName: userInfo['name'] as String?,
        email: userInfo['email'] as String?,
        photoUrl: userInfo['picture'] as String?,
      );
    } on Exception {
      return null;
    }
  }

  /// Signs the user out and clears persisted credentials.
  Future<void> signOut() async {
    _authClient?.close();
    _authClient = null;
    await _clearPersistedCredentials();
  }

  /// Returns an authenticated HTTP client for use with `googleapis` APIs.
  ///
  /// When an [AutoRefreshingAuthClient] is available (after sign-in or session
  /// restore), returns a non-closing wrapper around it so callers that call
  /// `client.close()` don't kill the shared client. Otherwise falls back to
  /// constructing a client from the raw [accessToken].
  http.Client getAuthenticatedClient(String accessToken) {
    if (_authClient != null) return _NonClosingClient(_authClient!);

    final credentials = auth_io.AccessCredentials(
      auth_io.AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      _scopes,
    );
    return auth_io.authenticatedClient(http.Client(), credentials);
  }

  /// Attempts to restore a previous session from persisted credentials.
  /// Returns an [AuthState] on success, or null if no valid session exists.
  Future<AuthState?> tryRestoreSession() async {
    final credentials = await _loadPersistedCredentials();
    if (credentials == null || credentials.refreshToken == null) return null;

    try {
      final clientId = auth_io.ClientId(googleClientId, googleClientSecret);
      final client = auth_io.autoRefreshingClient(
        clientId,
        credentials,
        http.Client(),
      );

      _authClient = client;
      client.credentialUpdates.listen(_persistCredentials);

      final userInfo = await _fetchUserInfo(client);

      return AuthState(
        accessToken: client.credentials.accessToken.data,
        displayName: userInfo['name'] as String?,
        email: userInfo['email'] as String?,
        photoUrl: userInfo['picture'] as String?,
      );
    } on Exception {
      await _clearPersistedCredentials();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _openBrowser(String url) {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', url]);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else {
      Process.run('xdg-open', [url]);
    }
  }

  Future<Map<String, dynamic>> _fetchUserInfo(http.Client client) async {
    final response = await client.get(
      Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {};
  }

  static const _storage = FlutterSecureStorage();

  Future<void> _persistCredentials(auth_io.AccessCredentials credentials) async {
    final json = jsonEncode({
      'accessToken': {
        'type': credentials.accessToken.type,
        'data': credentials.accessToken.data,
        'expiry': credentials.accessToken.expiry.toIso8601String(),
      },
      'refreshToken': credentials.refreshToken,
      'scopes': credentials.scopes,
    });
    await _storage.write(key: _credentialsKey, value: json);
  }

  Future<auth_io.AccessCredentials?> _loadPersistedCredentials() async {
    final raw = await _storage.read(key: _credentialsKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final tokenMap = map['accessToken'] as Map<String, dynamic>;
      return auth_io.AccessCredentials(
        auth_io.AccessToken(
          tokenMap['type'] as String,
          tokenMap['data'] as String,
          DateTime.parse(tokenMap['expiry'] as String),
        ),
        map['refreshToken'] as String?,
        (map['scopes'] as List).cast<String>(),
      );
    } on Exception {
      return null;
    }
  }

  Future<void> _clearPersistedCredentials() async {
    await _storage.delete(key: _credentialsKey);
  }
}

/// Wrapper that delegates all requests but ignores [close], preventing callers
/// from accidentally closing the shared [AutoRefreshingAuthClient].
class _NonClosingClient extends http.BaseClient {
  final http.Client _inner;
  _NonClosingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() {} // intentional no-op
}
