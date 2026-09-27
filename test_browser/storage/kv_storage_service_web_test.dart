@TestOn('browser')
library;

import 'package:test/test.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

import '../web_databases.dart';

void main() {
  setUp(() => deleteDatabases(['app_kv_store']));

  test('keeps strings, lists and booleans across instances', () async {
    await KvStorageService().setString('name', 'Boolean');
    await KvStorageService().setStringList('ids', ['a', 'b']);
    await KvStorageService().setBoolean('on', true);

    final kv = KvStorageService();
    expect(await kv.getString('name'), 'Boolean');
    expect(await kv.getStringList('ids'), ['a', 'b']);
    expect(await kv.getBoolean('on'), isTrue);
  });

  test('has nothing for keys never saved', () async {
    final kv = KvStorageService();
    expect(await kv.getString('missing'), isNull);
    expect(await kv.getStringList('missing'), isNull);
    expect(await kv.getBoolean('missing'), isNull);
  });

  test('replaces and removes values', () async {
    final kv = KvStorageService();
    await kv.setString('name', 'old');
    await kv.setString('name', 'new');
    expect(await kv.getString('name'), 'new');

    await kv.remove('name');
    expect(await KvStorageService().getString('name'), isNull);
  });

  test('keeps every value written at the same time', () async {
    final kv = KvStorageService();
    await Future.wait([for (var i = 0; i < 10; i++) kv.setString('k$i', '$i')]);
    for (var i = 0; i < 10; i++) {
      expect(await kv.getString('k$i'), '$i');
    }
  });

  test('keeps text that needs escaping as it was', () async {
    const text = '{"quote":"\\"", "emoji":"❤️", "newline":"\n"}';
    await KvStorageService().setString('json', text);
    expect(await KvStorageService().getString('json'), text);
  });
}
