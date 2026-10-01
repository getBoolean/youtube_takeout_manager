import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_keys_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/model_capabilities_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/key_check.dart';

import '../key_check_fakes.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer container({
    AiKeys build = AiKeys.none,
    CheckedJev? jev,
    CheckedClaude? claude,
  }) {
    final c = ProviderContainer(
      overrides: [
        aiKeysRepositoryProvider.overrideWithValue(
          AiKeysRepository(
            CredentialStore(const FlutterSecureStorage()),
            build: build,
          ),
        ),
        typeSafeRepositoryProvider.overrideWithValue(jev ?? CheckedJev()),
        anthropicRepositoryProvider.overrideWithValue(
          claude ?? CheckedClaude(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<Map<AiService, KeyCheck>> save(
    ProviderContainer c,
    Map<AiService, String> keys,
  ) => c.read(aiKeysSetupProvider.notifier).save(keys);

  test('keys that work are in use straight away', () async {
    final c = container();
    expect((await c.read(aiKeysProvider.future)).hasAny, isFalse);

    final checks = await save(c, {
      AiService.jev: 'jv_live_1',
      AiService.claude: 'sk-ant-2',
    });

    expect(checks.values.map((check) => check.status), [
      KeyStatus.works,
      KeyStatus.works,
    ]);
    expect(
      c.read(aiKeysProvider).value,
      const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-2'),
    );
  });

  test('clearing a key turns its service off, without checking', () async {
    final claude = CheckedClaude();
    final c = container(claude: claude);
    await save(c, {AiService.claude: 'sk-ant-2'});

    await save(c, {AiService.claude: ''});

    expect(c.read(aiKeysProvider).value?.hasClaude, isFalse);
    expect(claude.checked, ['sk-ant-2']);
  });

  test('a service built in is left as it is', () async {
    final c = container(build: const AiKeys(typesafe: 'jv_built'));

    await save(c, {AiService.jev: 'jv_other', AiService.claude: 'sk-ant-2'});

    expect(
      c.read(aiKeysProvider).value,
      const AiKeys(typesafe: 'jv_built', anthropic: 'sk-ant-2'),
    );
  });

  test('a rejected key is not saved, and says so', () async {
    final c = container(jev: CheckedJev(const AiKeyRejected()));

    final checks = await save(c, {
      AiService.jev: 'jv_wrong',
      AiService.claude: 'sk-ant-2',
    });

    expect(checks[AiService.jev]?.status, KeyStatus.rejected);
    expect(c.read(aiKeysProvider).value, const AiKeys(anthropic: 'sk-ant-2'));
  });

  test('a key whose account needs credit is saved, saying so', () async {
    final c = container(
      claude: CheckedClaude(
        failure: const AiBillingProblem('Your credit balance is too low.'),
      ),
    );

    final checks = await save(c, {AiService.claude: 'sk-ant-2'});

    expect(checks[AiService.claude]?.status, KeyStatus.needsCredit);
    expect(checks[AiService.claude]?.detail, contains('credit balance'));
    expect(c.read(aiKeysProvider).value?.anthropic, 'sk-ant-2');
  });

  test("a key that can't use the model is saved, saying so", () async {
    final c = container(
      claude: CheckedClaude(failure: const AiModelUnavailable()),
    );

    final checks = await save(c, {AiService.claude: 'sk-ant-2'});

    expect(checks[AiService.claude]?.status, KeyStatus.modelUnavailable);
    expect(c.read(aiKeysProvider).value?.anthropic, 'sk-ant-2');
  });

  test("a model that can't answer in shapes is saved as unavailable", () async {
    final c = container(claude: CheckedClaude(structuredOutputs: false));

    final checks = await save(c, {AiService.claude: 'sk-ant-2'});

    expect(checks[AiService.claude]?.status, KeyStatus.modelUnavailable);
    expect(c.read(aiKeysProvider).value?.anthropic, 'sk-ant-2');
  });

  test(
    "a key for a service that can't be reached is saved, unchecked",
    () async {
      final c = container(jev: CheckedJev(const AiUnreachable()));

      final checks = await save(c, {AiService.jev: 'jv_live_1'});

      expect(checks[AiService.jev]?.status, KeyStatus.unchecked);
      expect(c.read(aiKeysProvider).value?.typesafe, 'jv_live_1');
    },
  );

  test("checking Claude's key keeps its model's capabilities", () async {
    final c = container();

    await save(c, {AiService.claude: 'sk-ant-2'});

    final kept = await c
        .read(modelCapabilitiesRepositoryProvider)
        .load(anthropicModel);
    expect(kept?.structuredOutputs, isTrue);
  });

  test('an unchanged key is not checked again', () async {
    final jev = CheckedJev();
    final c = container(jev: jev);
    await save(c, {AiService.jev: 'jv_live_1'});

    final checks = await save(c, {AiService.jev: ' jv_live_1 '});

    expect(jev.checked, ['jv_live_1']);
    expect(checks, isEmpty);
  });

  test(
    'a key with a space inside is refused, not saved, and not sent',
    () async {
      final jev = CheckedJev();
      final c = container(jev: jev);

      final checks = await save(c, {AiService.jev: 'jv_live 1'});

      expect(checks[AiService.jev]?.status, KeyStatus.rejected);
      expect(jev.checked, isEmpty);
      expect(c.read(aiKeysProvider).value?.hasJev, isFalse);
    },
  );
}
