@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository.dart';

import '../web_databases.dart';

const _a = 'UCaaaaaaaaaaaaaaaaaaaaaa';
const _b = 'UCbbbbbbbbbbbbbbbbbbbbbb';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

Map<String, String>? _text(Map<String, Uint8List>? files) =>
    files?.map((path, bytes) => MapEntry(path, utf8.decode(bytes)));

void main() {
  setUp(() => deleteDatabases(['takeouts', 'takeout_csvs']));

  test('keeps an account\'s files across instances', () async {
    await TakeoutRepository().saveCsvs(_a, {
      'comments/comments.csv': _bytes('a,b\n1,2'),
      'live chats/live chats.csv': _bytes('❤️'),
    });

    expect(_text(await TakeoutRepository().loadCsvs(_a)), {
      'comments/comments.csv': 'a,b\n1,2',
      'live chats/live chats.csv': '❤️',
    });
  });

  test('saving replaces the account\'s previously saved files', () async {
    final repo = TakeoutRepository();
    await repo.saveCsvs(_a, {'old.csv': _bytes('old')});
    await repo.saveCsvs(_a, {'new.csv': _bytes('new')});

    expect(_text(await repo.loadCsvs(_a)), {'new.csv': 'new'});
  });

  test('each account\'s files are kept separately', () async {
    final repo = TakeoutRepository();
    await repo.saveCsvs(_a, {'x.csv': _bytes('a')});
    await repo.saveCsvs(_b, {'x.csv': _bytes('b')});

    expect(_text(await repo.loadCsvs(_a)), {'x.csv': 'a'});
    expect(_text(await repo.loadCsvs(_b)), {'x.csv': 'b'});
    expect(await repo.listAccountIds(), unorderedEquals([_a, _b]));
  });

  test('an account with nothing saved loads as null', () async {
    expect(await TakeoutRepository().loadCsvs(_a), isNull);
    expect(await TakeoutRepository().listAccountIds(), isEmpty);
  });

  test('clearing an account leaves other accounts alone', () async {
    final repo = TakeoutRepository();
    await repo.saveCsvs(_a, {'x.csv': _bytes('a')});
    await repo.saveCsvs(_b, {'x.csv': _bytes('b')});

    await repo.clearCsvs(_a);

    expect(await repo.loadCsvs(_a), isNull);
    expect(_text(await repo.loadCsvs(_b)), {'x.csv': 'b'});
    expect(await repo.listAccountIds(), [_b]);
  });

  test('loads only the files asked for', () async {
    final repo = TakeoutRepository();
    await repo.saveCsvs(_a, {
      'comments/comments.csv': _bytes('c'),
      'live chats/live chats.csv': _bytes('l'),
    });

    final files = await repo.loadCsvs(
      _a,
      only: (path) => path.startsWith('comments/'),
    );
    expect(_text(files), {'comments/comments.csv': 'c'});
  });

  test('an account ID that is not a channel ID is rejected', () async {
    final repo = TakeoutRepository();
    expect(() => repo.saveCsvs('../x', {}), throwsArgumentError);
    expect(() => repo.loadCsvs('not-a-channel'), throwsArgumentError);
  });

  test('files saved before per-account storage load until cleared', () async {
    await writeRaw('takeout_csvs', 'files', {
      'comments/comments.csv': _bytes('legacy').toJS,
    });

    final repo = TakeoutRepository();
    expect(_text(await repo.loadLegacyCsvs()), {
      'comments/comments.csv': 'legacy',
    });

    await repo.clearLegacyCsvs();
    expect(await repo.loadLegacyCsvs(), isNull);
  });
}
