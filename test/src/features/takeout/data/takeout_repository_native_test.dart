import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository_native.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

Map<String, String>? _decoded(Map<String, Uint8List>? files) =>
    files?.map((path, bytes) => MapEntry(path, utf8.decode(bytes)));

void main() {
  late Directory support;
  late TakeoutRepositoryImpl repository;

  setUp(() {
    support = Directory.systemTemp.createTempSync('takeout_repo_test');
    addTearDown(() => support.deleteSync(recursive: true));
    repository = TakeoutRepositoryImpl(supportDirectory: () async => support);
  });

  void writeFile(String dir, String path, String content) {
    File('${support.path}/$dir/$path')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  test('saving replaces the account\'s previously saved files', () async {
    await repository.saveCsvs('UCme', {'a/old.csv': _bytes('old')});
    await repository.saveCsvs('UCme', {'b/new.csv': _bytes('new')});

    expect(_decoded(await repository.loadCsvs('UCme')), {'b/new.csv': 'new'});
  });

  test('each account\'s files are kept separately', () async {
    await repository.saveCsvs('UCme', {'a/mine.csv': _bytes('mine')});
    await repository.saveCsvs('UCother', {'a/theirs.csv': _bytes('theirs')});

    expect(_decoded(await repository.loadCsvs('UCme')), {'a/mine.csv': 'mine'});
    expect(_decoded(await repository.loadCsvs('UCother')), {
      'a/theirs.csv': 'theirs',
    });
  });

  test('an account with nothing saved loads as null', () async {
    expect(await repository.loadCsvs('UCme'), isNull);
  });

  test('clearing an account leaves other accounts alone', () async {
    await repository.saveCsvs('UCme', {'a/mine.csv': _bytes('mine')});
    await repository.saveCsvs('UCother', {'a/theirs.csv': _bytes('theirs')});

    await repository.clearCsvs('UCme');

    expect(await repository.loadCsvs('UCme'), isNull);
    expect(await repository.loadCsvs('UCother'), isNotNull);
  });

  test('an account ID that could escape its folder is rejected', () async {
    expect(
      () => repository.saveCsvs('../UCme', {'a.csv': _bytes('x')}),
      throwsArgumentError,
    );
  });

  test('an account ID that is not a channel ID is rejected', () async {
    for (final id in ['CON', 'NUL', 'x' * 300]) {
      expect(
        () => repository.saveCsvs(id, {'a.csv': _bytes('x')}),
        throwsArgumentError,
        reason: id,
      );
    }
  });

  test('keeps the previous files if saving stopped while writing', () async {
    writeFile('takeouts/UCme', 'a/old.csv', 'old');
    writeFile('takeouts/UCme.tmp', 'b/partial.csv', 'partial');

    expect(_decoded(await repository.loadCsvs('UCme')), {'a/old.csv': 'old'});
  });

  test('recovers the new files if saving stopped before swapping', () async {
    writeFile('takeouts/UCme.old', 'a/old.csv', 'old');
    writeFile('takeouts/UCme.tmp', 'b/new.csv', 'new');

    expect(_decoded(await repository.loadCsvs('UCme')), {'b/new.csv': 'new'});
    expect(_decoded(await repository.loadCsvs('UCme')), {'b/new.csv': 'new'});
  });

  test('a save after an interrupted one ignores its leftovers', () async {
    writeFile('takeouts/UCme', 'a/old.csv', 'old');
    writeFile('takeouts/UCme.tmp', 'b/partial.csv', 'partial');
    writeFile('takeouts/UCme.old', 'c/older.csv', 'older');

    await repository.saveCsvs('UCme', {'d/new.csv': _bytes('new')});

    expect(_decoded(await repository.loadCsvs('UCme')), {'d/new.csv': 'new'});
  });

  test('files saved before per-account storage load until cleared', () async {
    writeFile('takeout_csvs', 'Takeout/comments/comments.csv', 'legacy');

    expect(_decoded(await repository.loadLegacyCsvs()), {
      'Takeout/comments/comments.csv': 'legacy',
    });

    await repository.clearLegacyCsvs();

    expect(await repository.loadLegacyCsvs(), isNull);
  });

  group('listAccountIds', () {
    test('lists each saved takeout', () async {
      await repository.saveCsvs('UCme', {'a.csv': _bytes('a')});
      await repository.saveCsvs('UCother', {'a.csv': _bytes('a')});

      expect(
        await repository.listAccountIds(),
        unorderedEquals(['UCme', 'UCother']),
      );
    });

    test('lists a takeout whose save stopped after moving the old files '
        'aside', () async {
      writeFile('takeouts/UCme.tmp', 'a.csv', 'new');
      writeFile('takeouts/UCme.old', 'a.csv', 'old');

      expect(await repository.listAccountIds(), ['UCme']);
    });

    test('skips leftovers of a save and folders that are no channel', () async {
      writeFile('takeouts/UConlytmp.tmp', 'a.csv', 'new');
      writeFile('takeouts/UConlyold.old', 'a.csv', 'old');
      writeFile('takeouts/not a channel', 'a.csv', 'x');

      expect(await repository.listAccountIds(), isEmpty);
    });

    test('lists nothing before anything is saved', () async {
      expect(await repository.listAccountIds(), isEmpty);
    });
  });

  test('loads only the files asked for', () async {
    await repository.saveCsvs('UCme', {
      'small.csv': _bytes('small'),
      'big.csv': _bytes('big'),
    });

    final files = await repository.loadCsvs(
      'UCme',
      only: (path) => path.startsWith('small'),
    );

    expect(_decoded(files), {'small.csv': 'small'});
  });
}
