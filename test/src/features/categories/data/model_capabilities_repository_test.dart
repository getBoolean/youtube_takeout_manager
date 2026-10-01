import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/model_capabilities_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _sonnet = ModelCapabilities(
  id: 'claude-sonnet-5',
  structuredOutputs: true,
  lowEffort: true,
  maxTokens: 64000,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ModelCapabilitiesRepository repository() =>
      ModelCapabilitiesRepository(KvStorageService());

  test('capabilities saved load again after a restart', () async {
    await repository().save(_sonnet);

    expect(await repository().load('claude-sonnet-5'), _sonnet);
  });

  test("capabilities kept for another model aren't used", () async {
    await repository().save(_sonnet);

    expect(await repository().load('claude-haiku-4-5'), isNull);
  });

  test('nothing loads before anything is saved', () async {
    expect(await repository().load('claude-sonnet-5'), isNull);
  });

  test('capabilities that cannot be read load as none', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.anthropic_model_capabilities': '{"id": 3}',
    });

    expect(await repository().load('claude-sonnet-5'), isNull);
  });
}
