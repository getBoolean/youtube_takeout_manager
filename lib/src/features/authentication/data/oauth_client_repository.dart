import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/oauth_config.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/oauth_client.dart';

part 'oauth_client_repository.g.dart';

@Riverpod(keepAlive: true)
OAuthClientRepository oauthClientRepository(Ref ref) => OAuthClientRepository(
  ref.watch(kvStorageServiceProvider),
  buildClient: buildOAuthClient,
);

/// The Google Cloud client that signs in, or null until there is one.
@Riverpod(keepAlive: true)
Future<OAuthClient?> oauthClient(Ref ref) =>
    ref.watch(oauthClientRepositoryProvider).load();

/// The OAuth client sign-in uses: the build's, else one the user set up.
///
/// Kept with the other preferences rather than in secure storage: Google
/// doesn't treat an installed app's client secret as confidential, and
/// `CredentialStore` must be the only one writing secure storage, whose
/// writes it keeps in order.
class OAuthClientRepository {
  static const _key = 'oauth_client';

  final KvStorageService _kv;
  final OAuthClient? buildClient;

  OAuthClientRepository(this._kv, {this.buildClient});

  /// Whether users can set up their own client: only when the build has
  /// none.
  bool get canChange => buildClient == null;

  Future<OAuthClient?> load() async {
    if (buildClient case final client?) return client;
    final json = await _kv.getString(_key);
    if (json == null || json.isEmpty) return null;
    try {
      return OAuthClientMapper.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<void> save(OAuthClient client) {
    if (!canChange) throw StateError("This build's client can't be changed");
    return _kv.setString(_key, client.toJson());
  }

  Future<void> clear() => _kv.remove(_key);
}
