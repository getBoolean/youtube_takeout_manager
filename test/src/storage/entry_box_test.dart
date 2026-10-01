import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';

/// Keeps entries in memory; writes wait for [gate] while it's set, and
/// [failNext] makes the next write fail.
class _Gated extends MemoryEntryStore {
  Completer<void>? gate;
  bool failNext = false;

  @override
  Future<void> putAll(String box, Map<String, String> entries) async {
    await gate?.future;
    if (failNext) {
      failNext = false;
      throw StateError('write failed');
    }
    return super.putAll(box, entries);
  }
}

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

  group('saves overlapping', () {
    test('leave the box as the last save says', () async {
      final store = _Gated();
      final box = _items(store);
      await box.load();
      store.gate = Completer();

      final first = box.save({'a': const _Item(1), 'z': const _Item(26)});
      final second = box.save({'a': const _Item(1)});
      store.gate!.complete();
      await Future.wait([first, second]);

      expect((await _items(store).load()).keys, ['a']);
    });

    test('leave the box as the last save says, never loaded', () async {
      final store = _Gated();
      final box = _items(store);
      store.gate = Completer();

      final first = box.save({'a': const _Item(1), 'z': const _Item(26)});
      final second = box.save({'a': const _Item(1)});
      store.gate!.complete();
      await Future.wait([first, second]);

      expect((await _items(store).load()).keys, ['a']);
    });

    test('a load during a save sees what was saved', () async {
      final store = _Gated();
      final box = _items(store);
      await box.load();
      store.gate = Completer();

      final saving = box.save({'a': const _Item(1)});
      final loading = box.load();
      store.gate!.complete();
      await saving;

      expect((await loading).keys, ['a']);
    });

    test('a failed save lets the next one write all that changed since the '
        'last good save', () async {
      final store = _Gated();
      final box = _items(store);
      await box.save({'a': const _Item(1)});
      store
        ..gate = Completer()
        ..failNext = true;

      final failing = box.save({'a': const _Item(1), 'b': const _Item(2)});
      final next = box.save({
        'a': const _Item(1),
        'b': const _Item(2),
        'c': const _Item(3),
      });
      store.gate!.complete();

      await expectLater(failing, throwsStateError);
      await next;
      expect(await store.loadAll('items'), {'a': '1', 'b': '2', 'c': '3'});
    });

    test('of a set leave it as the last save says', () async {
      final store = _Gated();
      final ids = EntrySet(store, 'ids');
      await ids.load();
      store.gate = Completer();

      final first = ids.save({'a', 'z'});
      final second = ids.save({'a'});
      store.gate!.complete();
      await Future.wait([first, second]);

      expect(await EntrySet(store, 'ids').load(), {'a'});
    });
  });
}
