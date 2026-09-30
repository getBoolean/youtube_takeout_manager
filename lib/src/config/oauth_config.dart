import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:youtube_takeout_manager/src/features/authentication/domain/oauth_client.dart';

const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const googleClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

/// Web requires a separate "Web application" OAuth client ID because the
/// native Desktop client type does not support the browser token model.
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// The client this build was made with, or null for users to set up their
/// own. On web the token model does not require a client secret.
const OAuthClient? buildOAuthClient = kIsWeb
    ? (googleWebClientId == '' ? null : OAuthClient(id: googleWebClientId))
    : (googleClientId == '' || googleClientSecret == ''
          ? null
          : OAuthClient(id: googleClientId, secret: googleClientSecret));
