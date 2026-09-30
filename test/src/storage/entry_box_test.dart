import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';

/// Keeps entries in memory, recording each write.
class _Recording extends MemoryEntryStore {
  final puts = <Map<String, String>>[];
  final deletes = <List<String>>[];

  @override
  Future<void> putAll(String box, Map<String, String> entries) {
    puts.add({...entries});
    return super.putAll(box, entries);
  }

  @override
  Future<void> deleteAll(String box, List<String> keys) {
    deletes.add([...keys]);
    return super.deleteAll(box, keys);
  }
}

class _Item {
  final int n;

  const _Item(this.n);
}

EntryBox<_Item> _items(EntryStore store) => EntryBox(
  store,
  'items',
  encode: (item) => item.n,
  decode: (json) => _Item(json! as int),
);

void main() {
  test('values saved are loaded back', () async {
    final store = MemoryEntryStore();
    await _items(store).save({'a': const _Item(1), 'b': const _Item(2)});

    final loaded = await _items(store).load();
    expect(
      {for (final e in loaded.entries) e.key: e.value.n},
      {'a': 1, 'b': 2},
    );
  });

  test('saving writes only the entries that changed', () async {
    final store = _Recording();
    await _items(store).save({'a': const _Item(1), 'b': const _Item(2)});
    final box = _items(store);
    final loaded = await box.load();
    store.puts.clear();

    await box.save({...loaded, 'b': const _Item(3), 'c': const _Item(4)});

    expect(store.puts, [
      {'b': '3', 'c': '4'},
    ]);
    expect(store.deletes, isEmpty);
  });

  test('saving deletes the entries no longer there', () async {
    final store = _Recording();
    await _items(store).save({'a': const _Item(1), 'b': const _Item(2)});
    final box = _items(store);
    final loaded = await box.load();

    await box.save({'a': loaded['a']!});

    expect(store.deletes, [
      ['b'],
    ]);
    expect((await _items(store).load()).keys, ['a']);
  });

  test('an entry that cannot be read is skipped, keeping the rest', () async {
    final store = MemoryEntryStore({
      'items': {'a': '1', 'b': '"nonsense"'},
    });

    expect((await _items(store).load()).keys, ['a']);
  });

  test('saving before loading replaces what the box held', () async {
    final store = MemoryEntryStore({
      'items': {'old': '9'},
    });

    await _items(store).save({'a': const _Item(1)});

    expect(await store.loadAll('items'), {'a': '1'});
  });

  test('clearing empties the box', () async {
    final store = MemoryEntryStore();
    final box = _items(store);
    await box.save({'a': const _Item(1)});

    await box.clear();

    expect(await store.loadAll('items'), isEmpty);
  });

  test('a set keeps what is added and removed', () async {
    final store = _Recording();
    await EntrySet(store, 'ids').save({'a', 'b'});
    final ids = EntrySet(store, 'ids');
    await ids.load();
    store.puts.clear();

    await ids.save({'b', 'c'});

    expect(store.puts.single.keys, ['c']);
    expect(store.deletes.single, ['a']);
    expect(await EntrySet(store, 'ids').load(), {'b', 'c'});
  });
}
