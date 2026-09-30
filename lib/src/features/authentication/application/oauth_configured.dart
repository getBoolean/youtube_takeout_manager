import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/oauth_client_repository.dart';

part 'oauth_configured.g.dart';

/// Whether Google sign-in has a client, and with it everything that uses
/// the YouTube API. Overridable in tests.
@Riverpod(keepAlive: true)
bool oauthConfigured(Ref ref) => ref.watch(oauthClientProvider).value != null;
