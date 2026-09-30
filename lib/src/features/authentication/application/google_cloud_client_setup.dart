import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import '../data/credential_store.dart';
import '../data/oauth_client_repository.dart';
import '../domain/oauth_client.dart';
import 'saved_sign_ins.dart';

part 'google_cloud_client_setup.g.dart';

/// Sets up, changes or removes the Google Cloud client users bring when the
/// build has none. Nothing depends on it, so it can use any provider.
@Riverpod(keepAlive: true)
class GoogleCloudClientSetup extends _$GoogleCloudClientSetup {
  @override
  void build() {}

  /// Makes [client] the one sign-in uses. Unless it's the one already used,
  /// signs every channel out first.
  Future<void> save(OAuthClient client) async {
    if (await ref.read(oauthClientProvider.future) == client) return;
    await _leaveProject();
    await ref.read(oauthClientRepositoryProvider).save(client);
    await _reload();
  }

  /// Signs every channel out and turns sign-in off.
  Future<void> remove() async {
    await _leaveProject();
    await ref.read(oauthClientRepositoryProvider).clear();
    await _reload();
  }

  /// Sign-ins only work with the client that made them, and the quota
  /// belongs to its project, so neither carries over to another client.
  /// Drops saved sign-ins that weren't loaded too, e.g. ones kept while
  /// there was no client.
  Future<void> _leaveProject() async {
    final signIns = ref.read(savedSignInsProvider.notifier);
    await signIns.removeAll(
      (await ref.read(savedSignInsProvider.future)).keys.toSet(),
    );
    await ref.read(credentialStoreProvider).deleteAll();
    await ref.read(quotaProvider.notifier).resetUsage();
  }

  Future<void> _reload() async {
    ref.invalidate(oauthClientProvider);
    await ref.read(oauthClientProvider.future);
  }
}
