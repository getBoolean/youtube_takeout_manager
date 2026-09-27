import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/script_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ids = {'UgxAbc', 'UgyDef', 'ChwKGkNoat'};

  test('fills in every ID, leaving no placeholder behind', () async {
    final script = await ScriptGeneratorService().generateDeletionScript(ids);

    expect(script, isNot(matches(RegExp('__[A-Z_]+__'))));
    for (final id in ids) {
      expect(script, contains('"$id"'));
    }
  });

  test('an ID with quotes stays one JavaScript string', () async {
    final script = await ScriptGeneratorService().generateDeletionScript({
      'a"b',
    });

    expect(script, contains(r'"a\"b"'));
  });
}
