import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/oauth_config.dart';
import 'models/deletion_item_status.dart';
import 'providers/auth_providers.dart';
import 'providers/deletion_queue_provider.dart';

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
    if (isOAuthConfigured) {
      _initSession();
    }
  }

  Future<void> _initSession() async {
    await ref.read(authProvider.notifier).tryRestoreSession();
    // Auto-resume deletion queue if authenticated with pending items.
    if (ref.read(authProvider) != null) {
      final queue = await ref.read(deletionQueueProvider.future);
      if (queue.any((i) => i.status == DeletionItemStatus.pending)) {
        ref.read(deletionQueueProvider.notifier).startProcessing();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return App();
  }
}
