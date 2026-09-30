@TestOn('browser')
library;

import 'package:test/test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_backend_idb.dart';

import '../web_databases.dart';

void main() {
  setUp(() => deleteDatabases([IdbBackend.databaseName]));

  test('entries are kept by box and read back after reopening', () async {
    final first = await IdbBackend.open();
    await first.putAll(EntryBoxes.videos, {'v1': '{"a":1}', 'v2': '2'});
    await first.putAll(EntryBoxes.channelDetails, {'UCa': '{}'});
    await first.close();

    final again = await IdbBackend.open();
    expect(await again.loadAll(EntryBoxes.videos), {
      'v1': '{"a":1}',
      'v2': '2',
    });
    expect(await again.loadAll(EntryBoxes.channelDetails), {'UCa': '{}'});
    expect(await again.loadAll(EntryBoxes.videoFormats), isEmpty);
    await again.close();
  });

  test('entries can be deleted, and a box cleared', () async {
    final store = await IdbBackend.open();
    await store.putAll(EntryBoxes.videos, {'a': '1', 'b': '2'});

    await store.deleteAll(EntryBoxes.videos, ['a']);
    expect(await store.loadAll(EntryBoxes.videos), {'b': '2'});

    await store.clear(EntryBoxes.videos);
    expect(await store.loadAll(EntryBoxes.videos), isEmpty);
    await store.close();
  });
}
