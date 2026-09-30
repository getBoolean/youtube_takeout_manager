import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import '../data/ai_keys_repository.dart';

part 'ai_keys.g.dart';

/// The API keys the AI services categorize channels with: the build's, else
/// the ones entered in the app.
@Riverpod(keepAlive: true)
Future<AiKeys> aiKeys(Ref ref) => ref.watch(aiKeysRepositoryProvider).load();

/// Enters or clears the API keys of the AI services the build has none for.
/// Nothing depends on it, so it can use any provider.
@Riverpod(keepAlive: true)
class AiKeysSetup extends _$AiKeysSetup {
  @override
  void build() {}

  /// Uses [keys] from now on, each for its service; a blank one clears its
  /// service's key. Services whose key came with the build are left alone.
  Future<void> save(Map<AiService, String> keys) async {
    final repository = ref.read(aiKeysRepositoryProvider);
    for (final MapEntry(key: service, value: key) in keys.entries) {
      if (!repository.isBuiltIn(service)) await repository.save(service, key);
    }
    ref.invalidate(aiKeysProvider);
    await ref.read(aiKeysProvider.future);
  }
}
