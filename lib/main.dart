import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/app.dart';
import 'package:youtube_takeout_manager/src/config/oauth_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!isOAuthConfigured) {
    debugPrint(
      'WARNING: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET not set. '
      'Sign-in will be disabled.',
    );
  }

  // appEffects restores saved sign-ins (via legacySignInMigration) once App
  // starts listening to it.
  runApp(const ProviderScope(child: App()));
}
