import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_keys_repository.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProviderContainer container({AiKeys build = AiKeys.none}) {
    final c = ProviderContainer(
      overrides: [
        aiKeysRepositoryProvider.overrideWithValue(
          AiKeysRepository(
            CredentialStore(const FlutterSecureStorage()),
            build: build,
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('keys saved in the app are in use straight away', () async {
    final c = container();
    expect((await c.read(aiKeysProvider.future)).hasAny, isFalse);

    await c.read(aiKeysSetupProvider.notifier).save({
      AiService.jev: 'jv_live_1',
      AiService.claude: 'sk-ant-2',
    });

    expect(
      c.read(aiKeysProvider).value,
      const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-2'),
    );
  });

  test('clearing a key turns its service off', () async {
    final c = container();
    await c.read(aiKeysSetupProvider.notifier).save({
      AiService.claude: 'sk-ant-2',
    });

    await c.read(aiKeysSetupProvider.notifier).save({AiService.claude: ''});

    expect(c.read(aiKeysProvider).value?.hasClaude, isFalse);
  });

  test("a service built in is left as it is", () async {
    final c = container(build: const AiKeys(typesafe: 'jv_built'));

    await c.read(aiKeysSetupProvider.notifier).save({
      AiService.jev: 'jv_other',
      AiService.claude: 'sk-ant-2',
    });

    expect(
      c.read(aiKeysProvider).value,
      const AiKeys(typesafe: 'jv_built', anthropic: 'sk-ant-2'),
    );
  });
}
