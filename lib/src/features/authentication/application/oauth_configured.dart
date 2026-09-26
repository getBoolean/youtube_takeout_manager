import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';

part 'oauth_configured.g.dart';

/// Whether Google sign-in has a client configured. Overridable in tests.
@Riverpod(keepAlive: true)
bool oauthConfigured(Ref ref) => isOAuthConfigured;
