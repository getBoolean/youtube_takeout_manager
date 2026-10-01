import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_keys_repository.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  AiKeysRepository repository({AiKeys build = AiKeys.none}) => AiKeysRepository(
    CredentialStore(const FlutterSecureStorage()),
    build: build,
  );

  test('keys entered on this device are used after reopening', () async {
    await repository().save(AiService.jev, 'jv_live_1');
    await repository().save(AiService.claude, 'sk-ant-2');

    expect(
      await repository().load(),
      const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-2'),
    );
  });

  test('without keys, no AI service is on', () async {
    expect((await repository().load()).hasAny, isFalse);
  });

  test('a key is saved without the spaces pasted around it', () async {
    await repository().save(AiService.claude, '  sk-ant-2\n');

    expect((await repository().load()).anthropic, 'sk-ant-2');
  });

  test("a key that can't go in a request header is refused, without "
      'saying it', () async {
    await expectLater(
      repository().save(AiService.claude, 'sk-ant api03'),
      throwsA(
        isA<ArgumentError>().having(
          (e) => '$e',
          'text',
          isNot(contains('sk-ant api03')),
        ),
      ),
    );

    expect((await repository().load()).hasClaude, isFalse);
  });

  test('saving a blank key removes it', () async {
    await repository().save(AiService.claude, 'sk-ant-2');

    await repository().save(AiService.claude, '  ');

    expect((await repository().load()).hasClaude, isFalse);
  });

  test("the build's key is used, and can't be changed in the app", () async {
    final built = repository(build: const AiKeys(typesafe: 'jv_built'));

    expect(built.isBuiltIn(AiService.jev), isTrue);
    expect(built.isBuiltIn(AiService.claude), isFalse);
    expect(() => built.save(AiService.jev, 'jv_other'), throwsStateError);
    expect((await built.load()).typesafe, 'jv_built');
  });

  test(
    "the build's key wins over one entered before it was built in",
    () async {
      await repository().save(AiService.jev, 'jv_entered');

      final keys = await repository(
        build: const AiKeys(typesafe: 'jv_built'),
      ).load();

      expect(keys.typesafe, 'jv_built');
    },
  );

  test('a service the build has no key for can still get one', () async {
    final built = repository(build: const AiKeys(typesafe: 'jv_built'));

    await built.save(AiService.claude, 'sk-ant-2');

    expect(
      await built.load(),
      const AiKeys(typesafe: 'jv_built', anthropic: 'sk-ant-2'),
    );
  });
}
