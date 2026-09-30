import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/oauth_client_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/oauth_client.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

void main() {
  const pasted = OAuthClient(
    id: '123-abc.apps.googleusercontent.com',
    secret: 'GOCSPX-abc',
  );
  const built = OAuthClient(
    id: '456-def.apps.googleusercontent.com',
    secret: 'GOCSPX-def',
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // A fresh repository each time, as after a restart.
  OAuthClientRepository repository({OAuthClient? buildClient}) =>
      OAuthClientRepository(KvStorageService(), buildClient: buildClient);

  test('has no client until one is saved', () async {
    expect(await repository().load(), isNull);
  });

  test('keeps a saved client across restarts', () async {
    await repository().save(pasted);

    expect(await repository().load(), pasted);
  });

  test('forgets the client once cleared', () async {
    await repository().save(pasted);
    await repository().clear();

    expect(await repository().load(), isNull);
  });

  test("a corrupt saved client counts as none", () async {
    SharedPreferences.setMockInitialValues({
      'flutter.oauth_client': '{"secret":',
    });

    expect(await repository().load(), isNull);
  });

  test("the build's client wins and can't be changed", () async {
    await repository().save(pasted);
    final withBuild = repository(buildClient: built);

    expect(await withBuild.load(), built);
    expect(withBuild.canChange, isFalse);
    expect(repository().canChange, isTrue);
  });
}
