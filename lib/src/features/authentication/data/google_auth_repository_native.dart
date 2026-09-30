import 'dart:async';

import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../domain/oauth_client.dart';
import 'google_auth_repository.dart';

class GoogleAuthRepositoryImpl extends GoogleAuthRepository {
  final OAuthClient? _client;

  GoogleAuthRepositoryImpl(this._client);

  final _sessions =
      <
        String,
        ({
          auth_io.AutoRefreshingAuthClient client,
          StreamSubscription<auth_io.AccessCredentials> updates,
        })
      >{};

  auth_io.ClientId get _clientId => switch (_client) {
    final client? => auth_io.ClientId(client.id, client.secret),
    null => throw StateError('No Google Cloud client to sign in with'),
  };

  @override
  Future<auth_io.AccessCredentials?> requestCredentials() async {
    final client = http.Client();
    try {
      return await auth_io.obtainAccessCredentialsViaUserConsent(
        _clientId,
        scopes,
        client,
        _openBrowser,
      );
    } on auth_io.UserConsentException {
      return null;
    } finally {
      client.close();
    }
  }

  @override
  bool isUsable(auth_io.AccessCredentials credentials) =>
      credentials.refreshToken != null;

  @override
  http.Client clientFor(auth_io.AccessCredentials credentials) =>
      auth_io.autoRefreshingClient(_clientId, credentials, http.Client());

  @override
  void addSession(
    String channelId,
    auth_io.AccessCredentials credentials, {
    required void Function(auth_io.AccessCredentials credentials) onRefreshed,
  }) {
    unawaited(closeSession(channelId));
    final client = auth_io.autoRefreshingClient(
      _clientId,
      credentials,
      http.Client(),
    );
    _sessions[channelId] = (
      client: client,
      updates: client.credentialUpdates.listen(onRefreshed),
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
    // Stop saving refreshed tokens first, so a refresh in flight can't save
    // one for a removed sign-in.
    await session.updates.cancel();
    session.client.close();
  }

  /// Opens Google's consent page, always asking which account and channel
  /// to use, and to consent again so a refresh token is always issued.
  void _openBrowser(String url) {
    final uri = Uri.parse(url);
    launchUrl(
      uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'prompt': 'select_account consent',
        },
      ),
    );
  }
}
