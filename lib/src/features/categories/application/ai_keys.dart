import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import '../data/ai_errors.dart';
import '../data/ai_keys_repository.dart';
import '../data/anthropic_repository.dart';
import '../data/model_capabilities_repository.dart';
import '../data/typesafe_repository.dart';
import '../domain/key_check.dart';

part 'ai_keys.g.dart';

/// The API keys the AI services categorize channels with: the build's, else
/// the ones entered in the app.
@Riverpod(keepAlive: true)
Future<AiKeys> aiKeys(Ref ref) => ref.watch(aiKeysRepositoryProvider).load();

/// Enters or clears the API keys of the AI services the build has none for,
/// checking each new key with its service first. Nothing depends on it, so
/// it can use any provider.
@Riverpod(keepAlive: true)
class AiKeysSetup extends _$AiKeysSetup {
  @override
  void build() {}

  /// Uses [keys] from now on, each for its service, trimmed; a blank one
  /// clears its service's key. Each new key is checked first, and kept
  /// unless rejected; what each check found is given by service. Keys the
  /// same as saved aren't checked again, and services whose key came with
  /// the build are left alone.
  Future<Map<AiService, KeyCheck>> save(Map<AiService, String> keys) async {
    final repository = ref.read(aiKeysRepositoryProvider);
    final saved = await repository.load();
    final toSave = {
      for (final MapEntry(key: service, value: key) in keys.entries)
        if (!repository.isBuiltIn(service)) service: key.trim(),
    };
    // Both at once.
    final checking = {
      for (final MapEntry(key: service, value: key) in toSave.entries)
        if (key.isNotEmpty && key != saved.keyFor(service))
          service: _check(service, key),
    };
    final checks = {
      for (final MapEntry(key: service, value: check) in checking.entries)
        service: await check,
    };
    for (final MapEntry(key: service, value: key) in toSave.entries) {
      if (checks[service]?.keeps ?? true) await repository.save(service, key);
    }
    ref.invalidate(aiKeysProvider);
    await ref.read(aiKeysProvider.future);
    return checks;
  }

  /// What [service] says about [key]: for Claude, also whether it can use
  /// the model, whose capabilities are kept.
  Future<KeyCheck> _check(AiService service, String key) async {
    if (!isHeaderSafeKey(key)) {
      return const KeyCheck(
        KeyStatus.rejected,
        "It has characters a request can't carry, such as a space or a line "
        'break.',
      );
    }
    try {
      switch (service) {
        case AiService.jev:
          await ref.read(typeSafeRepositoryProvider).checkKey(key);
        case AiService.claude:
          final model = await ref
              .read(anthropicRepositoryProvider)
              .capabilities(apiKey: key, model: anthropicModel);
          await ref.read(modelCapabilitiesRepositoryProvider).save(model);
          if (!model.structuredOutputs) {
            return const KeyCheck(
              KeyStatus.modelUnavailable,
              "It can't answer in the shape categorizing needs.",
            );
          }
      }
      return const KeyCheck(KeyStatus.works);
    } on AiFailure catch (e) {
      return switch (e) {
        AiKeyRejected() => const KeyCheck(KeyStatus.rejected),
        AiBillingProblem(:final message) => KeyCheck(
          KeyStatus.needsCredit,
          message,
        ),
        AiModelUnavailable(:final message) => KeyCheck(
          KeyStatus.modelUnavailable,
          message,
        ),
        AiUnreachable() ||
        AiOverloaded() ||
        AiRateLimited() => const KeyCheck(KeyStatus.unchecked),
        _ => KeyCheck(KeyStatus.unchecked, e.message),
      };
    }
  }
}
