import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/oauth_config.dart';
import 'providers/auth_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!isOAuthConfigured) {
    debugPrint('WARNING: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET not set. '
        'Sign-in will be disabled.');
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
    if (isOAuthConfigured) {
      ref.read(authProvider.notifier).tryRestoreSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return App();
  }
}
