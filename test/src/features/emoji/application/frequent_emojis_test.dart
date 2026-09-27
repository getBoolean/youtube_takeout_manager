import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/application/frequent_emojis.dart';
import 'package:youtube_takeout_manager/src/features/emoji/data/frequent_emoji_repository.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_use.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

void main() {
  ProviderContainer container() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  Future<List<String>> ids(ProviderContainer container) async => [
    for (final use in await container.read(frequentEmojisProvider.future))
      use.id,
  ];

  test('orders by use count, then most recent', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    final notifier = c.read(frequentEmojisProvider.notifier);
    await notifier.recordUse('u:a');
    await notifier.recordUse('u:b');
    await notifier.recordUse('u:c');
    await notifier.recordUse('u:b');

    expect(await ids(c), ['u:b', 'u:c', 'u:a']);
    final uses = await c.read(frequentEmojisProvider.future);
    expect(uses.first.count, 2);
  });

  test('persists across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final first = container();
    await first.read(frequentEmojisProvider.notifier).recordUse('c:key');

    expect(await ids(container()), ['c:key']);
  });

  test('drops the least recently used entry once full', () async {
    SharedPreferences.setMockInitialValues({});
    // The most used, but the least recently.
    final old = EmojiUse(
      id: 'u:old',
      count: 5,
      lastUsed: DateTime(2026, 1, 10),
    );
    await FrequentEmojiRepository(KvStorageService()).saveUses([
      old,
      for (var i = 1; i < maxFrequentEmojis; i++)
        EmojiUse(id: 'u:$i', count: 1, lastUsed: DateTime(2026, 1, 20)),
    ]);
    final c = container();
    await c.read(frequentEmojisProvider.notifier).recordUse('u:new');

    final result = await ids(c);
    expect(result, hasLength(maxFrequentEmojis));
    expect(result, isNot(contains('u:old')));
    expect(result, contains('u:new'));
  });
}
