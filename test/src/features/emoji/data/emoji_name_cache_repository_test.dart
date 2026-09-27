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

  test('saves names in the same format', () async {
    SharedPreferences.setMockInitialValues({});
    await repository().saveNames({
      'k1': const ResolvedEmoji(name: 'shortsad', ownerChannelId: 'UC1'),
      'k2': const ResolvedEmoji(name: 'wave'),
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cached_emoji_names'), _stored);
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
}
