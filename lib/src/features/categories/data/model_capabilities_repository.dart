import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/model_capabilities.dart';

part 'model_capabilities_repository.g.dart';

@Riverpod(keepAlive: true)
ModelCapabilitiesRepository modelCapabilitiesRepository(Ref ref) =>
    ModelCapabilitiesRepository(ref.watch(kvStorageServiceProvider));

/// Keeps the capabilities of the Claude model in use, as the Models API
/// gave them, so they're asked for once, and again when the model changes.
class ModelCapabilitiesRepository {
  static const _key = 'anthropic_model_capabilities';

  final KvStorageService _kv;

  ModelCapabilitiesRepository(this._kv);

  /// [model]'s capabilities, or null when those kept are another model's,
  /// or can't be read.
  Future<ModelCapabilities?> load(String model) async {
    final raw = await _kv.getString(_key);
    if (raw == null) return null;
    try {
      final capabilities = ModelCapabilitiesMapper.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return capabilities.id == model ? capabilities : null;
    } on Object {
      return null;
    }
  }

  Future<void> save(ModelCapabilities capabilities) =>
      _kv.setString(_key, jsonEncode(capabilities.toMap()));
}
