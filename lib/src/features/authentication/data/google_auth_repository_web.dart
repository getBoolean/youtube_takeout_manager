import 'package:googleapis_auth/auth_browser.dart';
import 'package:http/http.dart' as http;

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'google_auth_repository.dart';

/// On web there are no refresh tokens: a sign-in lasts as long as its access
/// token, about an hour.
class GoogleAuthRepositoryImpl extends GoogleAuthRepository {
  static const _expiryBuffer = Duration(minutes: 5);

  final _sessions = <String, ({http.Client client, String accessToken})>{};

  @override
  Future<AccessCredentials?> requestCredentials() async {
    try {
      // Google asks which account to use by default.
      return await requestAccessCredentials(
        clientId: googleWebClientId,
        scopes: scopes,
      );
    } on UserConsentException {
      return null;
    }
  }

  @override
  bool isUsable(AccessCredentials credentials) => credentials.accessToken.expiry
      .isAfter(DateTime.now().toUtc().add(_expiryBuffer));

  @override
  http.Client clientFor(AccessCredentials credentials) =>
      authenticatedClient(http.Client(), credentials);

  @override
  void addSession(
    String channelId,
    AccessCredentials credentials, {
    required void Function(AccessCredentials credentials) onRefreshed,
  }) {
    _sessions.remove(channelId)?.client.close();
    _sessions[channelId] = (
      client: authenticatedClient(http.Client(), credentials),
      accessToken: credentials.accessToken.data,
    );
  }

  @override
  bool hasSession(String channelId) => _sessions.containsKey(channelId);

  @override
  http.Client getAuthenticatedClient(String channelId) {
    final session = _sessions[channelId];
    if (session == null) {
      throw StateError('No sign-in for channel $channelId');
    }
    return NonClosingClient(session.client);
  }

  @override
  Future<void> closeSession(String channelId, {bool revoke = false}) async {
    final session = _sessions.remove(channelId);
    if (session == null) return;
    session.client.close();
    if (revoke) {
      try {
        await revokeConsent(session.accessToken);
      } on Exception {
        // Best-effort revocation.
      }
    }
  }
}
