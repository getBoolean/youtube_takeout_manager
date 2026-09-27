import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/data/emoji_name_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/resolved_emoji.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

const _key = 'flutter.cached_emoji_names';

/// Names as the app has always stored them.
const _stored =
    '{"k1":{"name":"shortsad","owner":"UC1"},"k2":{"name":"wave","owner":null}}';

void main() {
  EmojiNameCacheRepository repository() =>
      EmojiNameCacheRepository(KvStorageService());

  test('loads names stored in the existing format', () async {
    SharedPreferences.setMockInitialValues({_key: _stored});
    final names = await repository().loadNames();

    expect(names.keys, ['k1', 'k2']);
    expect(names['k1']!.name, 'shortsad');
    expect(names['k1']!.ownerChannelId, 'UC1');
    expect(names['k2']!.name, 'wave');
    expect(names['k2']!.ownerChannelId, isNull);
  });

  test('saved names load again after a restart', () async {
    SharedPreferences.setMockInitialValues({});
    await repository().saveNames({
      'k1': const ResolvedEmoji(name: 'shortsad', ownerChannelId: 'UC1'),
      'k2': const ResolvedEmoji(name: 'wave'),
    });

    final names = await repository().loadNames();
    expect(names.keys, unorderedEquals(['k1', 'k2']));
    expect(names['k1']!.name, 'shortsad');
    expect(names['k1']!.ownerChannelId, 'UC1');
    expect(names['k2']!.name, 'wave');
    expect(names['k2']!.ownerChannelId, isNull);
  });

  test('drops entries that are not valid names', () async {
    SharedPreferences.setMockInitialValues({
      _key:
          '{"ok":{"name":"ok"},"spaces":{"name":"a b"},"number":{"name":5},'
          '"list":[],"owner":{"name":"x","owner":7}}',
    });
    final names = await repository().loadNames();

    expect(names.keys, unorderedEquals(['ok', 'owner']));
    expect(names['ok']!.ownerChannelId, isNull);
    expect(names['owner']!.ownerChannelId, isNull);
  });

  test('ignores corrupt data', () async {
    SharedPreferences.setMockInitialValues({_key: 'not json'});
    expect(await repository().loadNames(), isEmpty);
  });

  test('loads nothing before anything is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = EmojiNameCacheRepository(KvStorageService());

    expect(await repository.loadNames(), isEmpty);
    expect(await repository.loadAttempts(), isEmpty);
    expect(await repository.loadPausedUntil(), isNull);
  });

  test('saved scan times load again after a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final attempts = {
      'v1': DateTime.utc(2026, 3, 4, 5, 6, 7),
      'v2': DateTime(2026, 1, 2),
    };
    await repository().saveAttempts(attempts);

    expect(await repository().loadAttempts(), attempts);
  });

  test('a saved pause loads again after a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final until = DateTime.utc(2026, 5, 6, 7, 8, 9);
    await repository().savePausedUntil(until);

    expect(await repository().loadPausedUntil(), until);
  });

  test('ignores corrupt scan times and pauses', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.emoji_resolve_attempts':
          '{"ok":"2026-01-02T00:00:00.000Z","number":5,"text":"soon"}',
      'flutter.emoji_lookup_paused_until': 'not a date',
    });

    expect(await repository().loadAttempts(), {'ok': DateTime.utc(2026, 1, 2)});
    expect(await repository().loadPausedUntil(), isNull);

    SharedPreferences.setMockInitialValues({
      'flutter.emoji_resolve_attempts': 'not json',
    });
    expect(await repository().loadAttempts(), isEmpty);
  });
}
