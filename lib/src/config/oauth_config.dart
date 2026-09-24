import 'package:flutter/foundation.dart' show kIsWeb;

const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const googleClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

/// Web requires a separate "Web application" OAuth client ID because the
/// native Desktop client type does not support the browser token model.
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// On web the token model does not require a client secret.
const bool isOAuthConfigured = kIsWeb
    ? googleWebClientId != ''
    : googleClientId != '' && googleClientSecret != '';
