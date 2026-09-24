import 'dart:convert';

import 'package:flutter/foundation.dart' show protected;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

import '../domain/auth_state.dart';

import 'google_auth_service_stub.dart'
    if (dart.library.io) 'google_auth_service_native.dart'
    if (dart.library.js_interop) 'google_auth_service_web.dart'
    as platform;

const scopes = [
  'https://www.googleapis.com/auth/youtube.force-ssl',
  'openid',
  'email',
  'profile',
];

const credentialsKey = 'google_auth_credentials';

/// Service for Google OAuth2 authentication.
///
/// Platform-specific implementations handle the actual sign-in flow:
/// - Native (Windows/macOS/Linux): local HTTP server redirect via `auth_io`
/// - Web: Google Identity Services popup via `auth_browser`
abstract class GoogleAuthService {
  GoogleAuthService();

  static final GoogleAuthService instance = platform.createGoogleAuthService();

  http.Client? get authClient;

  Future<AuthState?> signIn();
  Future<void> signOut();
  http.Client getAuthenticatedClient(String accessToken);
  Future<AuthState?> tryRestoreSession();

  // ---------------------------------------------------------------------------
  // Shared helpers (for subclass use only)
  // ---------------------------------------------------------------------------

  @protected
  AuthState buildAuthState(String accessToken, Map<String, dynamic> userInfo) {
    return AuthState(
      accessToken: accessToken,
      displayName: userInfo['name'] as String?,
      email: userInfo['email'] as String?,
      photoUrl: userInfo['picture'] as String?,
    );
  }

  @protected
  Future<Map<String, dynamic>> fetchUserInfo(http.Client client) async {
    final response = await client.get(
      Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {};
  }

  @protected
  static const storage = FlutterSecureStorage();

  @protected
  Future<void> persistCredentials(AccessCredentials credentials) async {
    final json = jsonEncode({
      'accessToken': {
        'type': credentials.accessToken.type,
        'data': credentials.accessToken.data,
        'expiry': credentials.accessToken.expiry.toIso8601String(),
      },
      'refreshToken': credentials.refreshToken,
      'scopes': credentials.scopes,
    });
    await storage.write(key: credentialsKey, value: json);
  }

  @protected
  Future<AccessCredentials?> loadPersistedCredentials() async {
    final raw = await storage.read(key: credentialsKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final tokenMap = map['accessToken'] as Map<String, dynamic>;
      return AccessCredentials(
        AccessToken(
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

  @protected
  Future<void> clearPersistedCredentials() async {
    await storage.delete(key: credentialsKey);
  }
}

/// Wrapper that delegates all requests but ignores [close], preventing callers
/// from accidentally closing the shared auth client.
class NonClosingClient extends http.BaseClient {
  final http.Client _inner;
  NonClosingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() {} // intentional no-op
}
