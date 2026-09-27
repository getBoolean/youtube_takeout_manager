import 'dart:convert';

import 'package:googleapis/youtube/v3.dart' show DetailedApiRequestError;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'google_auth_repository_stub.dart'
    if (dart.library.io) 'google_auth_repository_native.dart'
    if (dart.library.js_interop) 'google_auth_repository_web.dart'
    as platform;

part 'google_auth_repository.g.dart';

@Riverpod(keepAlive: true)
GoogleAuthRepository googleAuthRepository(Ref ref) =>
    GoogleAuthRepository.platform();

const scopes = [
  'https://www.googleapis.com/auth/youtube.force-ssl',
  'openid',
  'email',
  'profile',
];

/// Whether [error] means a sign-in stopped working: Google refused to
/// refresh it (access revoked, account deleted) or the API rejected its
/// token. Google being down, a rate limit, or a captive portal's page in
/// place of the token endpoint's reply don't count, so a sign-in isn't lost
/// to a bad connection.
bool isSignInFailure(Object error) => switch (error) {
  ServerRequestFailedException(
    statusCode: 400 || 401,
    responseContent: {'error': 'invalid_grant' || 'unauthorized_client'},
  ) =>
    true,
  AccessDeniedException() => true,
  DetailedApiRequestError(status: 401) => true,
  _ => false,
};

/// Google OAuth2 sign-ins, one session per YouTube channel.
///
/// Platform-specific implementations handle the actual sign-in flow:
/// - Native (Windows/macOS/Linux): local HTTP server redirect via `auth_io`
/// - Web: Google Identity Services popup via `auth_browser`
abstract class GoogleAuthRepository {
  GoogleAuthRepository();

  /// This platform's implementation. Named, so implementations and fakes
  /// can extend this class and share [fetchUserInfo].
  factory GoogleAuthRepository.platform() = platform.GoogleAuthRepositoryImpl;

  /// Asks the user to sign in, choosing an account and channel. Null if they
  /// cancel or refuse.
  Future<AccessCredentials?> requestCredentials();

  /// Whether saved [credentials] can still be used: on native, whether they
  /// can be refreshed; on web, where they can't, whether they're still valid.
  bool isUsable(AccessCredentials credentials);

  /// A client for [credentials], e.g. to look up their channel. The caller
  /// closes it.
  http.Client clientFor(AccessCredentials credentials);

  /// Keeps a session for [channelId], calling [onRefreshed] with each
  /// refreshed token. Replaces any session it had.
  void addSession(
    String channelId,
    AccessCredentials credentials, {
    required void Function(AccessCredentials credentials) onRefreshed,
  });

  bool hasSession(String channelId);

  /// A client for [channelId]'s session. Closing it does nothing, so callers
  /// can't close the shared session.
  http.Client getAuthenticatedClient(String channelId);

  /// Ends [channelId]'s session. [revoke] also revokes its token where the
  /// platform can (web).
  Future<void> closeSession(String channelId, {bool revoke = false});

  /// The Google account's name, email and photo.
  Future<Map<String, dynamic>> fetchUserInfo(http.Client client) async {
    final response = await client.get(
      Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {};
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
