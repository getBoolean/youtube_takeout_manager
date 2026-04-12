import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;

import '../models/auth_state.dart';

const _youtubeScope = 'https://www.googleapis.com/auth/youtube.force-ssl';

/// Service for Google OAuth2 authentication.
///
/// Uses `google_sign_in` on mobile/web. Desktop platforms (Windows/macOS/Linux)
/// are not yet supported by `google_sign_in` — a future implementation could
/// use `googleapis_auth.clientViaUserConsent()` with a browser-based flow.
class GoogleAuthService {
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  /// Initializes the Google Sign-In SDK. Must be called once at app startup.
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  /// Triggers the interactive sign-in flow.
  /// Returns an [AuthState] on success, or null if cancelled.
  Future<AuthState?> signIn() async {
    try {
      final account = await _googleSignIn.authenticate();
      final authClient = account.authorizationClient;
      final authorization = await authClient.authorizeScopes([_youtubeScope]);

      return AuthState(
        accessToken: authorization.accessToken,
        displayName: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
      );
    } on GoogleSignInException {
      return null;
    }
  }

  /// Signs the user out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Returns an authenticated HTTP client for use with `googleapis` APIs.
  /// The [accessToken] should come from the current [AuthState].
  http.Client getAuthenticatedClient(String accessToken) {
    final credentials = auth_io.AccessCredentials(
      auth_io.AccessToken(
        'Bearer',
        accessToken,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      null,
      [_youtubeScope],
    );
    return auth_io.authenticatedClient(http.Client(), credentials);
  }
}
