import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';

part 'ai_keys_repository.g.dart';

@Riverpod(keepAlive: true)
AiKeysRepository aiKeysRepository(Ref ref) =>
    AiKeysRepository(ref.watch(credentialStoreProvider), build: buildAiKeys);

/// The API keys for the AI services that categorize channels: the build's,
/// and, for a service the build has none for, one entered in the app.
///
/// Entered keys live in secure storage, through [CredentialStore], the one
/// thing that writes it.
class AiKeysRepository {
  final CredentialStore _store;
  final AiKeys build;

  AiKeysRepository(this._store, {this.build = AiKeys.none});

  /// Whether [service]'s key came with the build, so it can't be changed in
  /// the app.
  bool isBuiltIn(AiService service) => build.has(service);

  /// The keys in use: the build's, else the ones entered.
  Future<AiKeys> load() async {
    final entered = await _store.loadApiKeys();
    String keyFor(AiService service) =>
        isBuiltIn(service) ? build.keyFor(service) : entered[service] ?? '';
    return AiKeys(
      typesafe: keyFor(AiService.jev),
      anthropic: keyFor(AiService.claude),
    );
  }

  /// Uses [key] for [service] from now on; a blank one removes its key.
  Future<void> save(AiService service, String key) {
    if (isBuiltIn(service)) {
      throw StateError("This build's ${service.name} key can't be changed");
    }
    final trimmed = key.trim();
    return trimmed.isEmpty
        ? _store.deleteApiKey(service)
        : _store.saveApiKey(service, trimmed);
  }
}
