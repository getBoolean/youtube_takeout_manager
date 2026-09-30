import 'dart:convert';

import 'entry_store.dart';

/// One box of an [EntryStore] as a map of [T]s, each value kept as JSON on
/// its own. Saving writes only the values that changed since the last load
/// or save (compared by identity, as stores replace only what changed), and
/// deletes the ones gone.
class EntryBox<T extends Object> {
  final EntryStore _store;
  final String name;
  final Object? Function(T value) _encode;
  final T Function(Object? json) _decode;

  /// What the box holds, as last loaded or saved; null until then.
  Map<String, T>? _saved;

  EntryBox(
    this._store,
    this.name, {
    required Object? Function(T value) encode,
    required T Function(Object? json) decode,
  }) : _encode = encode,
       _decode = decode;

  /// Every value, skipping entries that can't be read.
  Future<Map<String, T>> load() async {
    final values = <String, T>{};
    for (final MapEntry(:key, :value) in (await _store.loadAll(name)).entries) {
      try {
        values[key] = _decode(jsonDecode(value));
      } on Object {
        // Unreadable: left out, as a blob's bad entries always were.
      }
    }
    _saved = Map.of(values);
    return values;
  }

  /// Makes the box hold exactly [values].
  Future<void> save(Map<String, T> values) async {
    final saved = _saved;
    if (saved == null) {
      // Never loaded: what the box holds is unknown, so it's replaced.
      await _store.clear(name);
      await _store.putAll(name, {
        for (final MapEntry(:key, :value) in values.entries)
          key: jsonEncode(_encode(value)),
      });
    } else {
      final changed = {
        for (final MapEntry(:key, :value) in values.entries)
          if (!identical(saved[key], value)) key: jsonEncode(_encode(value)),
      };
      final gone = [
        for (final key in saved.keys)
          if (!values.containsKey(key)) key,
      ];
      if (changed.isNotEmpty) await _store.putAll(name, changed);
      if (gone.isNotEmpty) await _store.deleteAll(name, gone);
    }
    _saved = Map.of(values);
  }

  Future<void> clear() async {
    await _store.clear(name);
    _saved = {};
  }
}

/// One box of an [EntryStore] as a set of keys, such as IDs YouTube no
/// longer has. Saving writes only what was added or removed.
class EntrySet {
  final EntryStore _store;
  final String name;
  Set<String>? _saved;

  EntrySet(this._store, this.name);

  Future<Set<String>> load() async {
    final keys = (await _store.loadAll(name)).keys.toSet();
    _saved = {...keys};
    return keys;
  }

  Future<void> save(Set<String> keys) async {
    final saved = _saved;
    if (saved == null) {
      await _store.clear(name);
      await _store.putAll(name, {for (final key in keys) key: '1'});
    } else {
      final added = keys.difference(saved);
      final gone = saved.difference(keys);
      if (added.isNotEmpty) {
        await _store.putAll(name, {for (final key in added) key: '1'});
      }
      if (gone.isNotEmpty) await _store.deleteAll(name, gone.toList());
    }
    _saved = {...keys};
  }

  Future<void> clear() async {
    await _store.clear(name);
    _saved = {};
  }
}
