import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/data/frequent_emoji_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_use.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _key = 'flutter.emoji.frequentlyUsed';

/// Uses as the app has always stored them.
const _stored =
    '[{"id":"u:🔥","count":3,"lastUsed":"2026-01-02T03:04:05.000Z"},'
    '{"id":"c:key","count":1,"lastUsed":"2026-01-01T00:00:00.000Z"}]';

final _uses = [
  EmojiUse(id: 'u:🔥', count: 3, lastUsed: DateTime.utc(2026, 1, 2, 3, 4, 5)),
  EmojiUse(id: 'c:key', count: 1, lastUsed: DateTime.utc(2026)),
];

void main() {
  FrequentEmojiRepository repository() =>
      FrequentEmojiRepository(KvStorageService());

  test('loads uses stored in the existing format', () async {
    SharedPreferences.setMockInitialValues({_key: _stored});
    expect(await repository().loadUses(), _uses);
  });

  test('saves uses in the same format', () async {
    SharedPreferences.setMockInitialValues({});
    await repository().saveUses(_uses);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('emoji.frequentlyUsed'), _stored);
  });

  test('loads nothing before anything is saved', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await repository().loadUses(), isEmpty);
  });

  test('ignores corrupt data', () async {
    SharedPreferences.setMockInitialValues({_key: 'not json'});
    expect(await repository().loadUses(), isEmpty);

    SharedPreferences.setMockInitialValues({_key: '{"id":"u:a"}'});
    expect(await repository().loadUses(), isEmpty);

    SharedPreferences.setMockInitialValues({
      _key:
          '[{"id":"u:a","count":1,"lastUsed":"2026-01-01T00:00:00.000"},'
          '{"id":5},null]',
    });
    expect(await repository().loadUses(), [
      EmojiUse(id: 'u:a', count: 1, lastUsed: DateTime(2026)),
    ]);
  });
}
