const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const googleClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');
const bool isOAuthConfigured =
    googleClientId != '' && googleClientSecret != '';
