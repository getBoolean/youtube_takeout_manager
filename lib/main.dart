import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/app.dart';
import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!isOAuthConfigured) {
    debugPrint(
      'WARNING: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET not set. '
      'Sign-in will be disabled.',
    );
  }

  runApp(const ProviderScope(child: _AppWrapper()));
}

class _AppWrapper extends ConsumerStatefulWidget {
  const _AppWrapper();

  @override
  ConsumerState<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<_AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Restores saved sign-ins now, so the viewed channel is signed in by the
    // time it shows.
    if (isOAuthConfigured) ref.read(savedSignInsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}
