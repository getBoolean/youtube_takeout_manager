import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/emoji/application/frequent_emojis.dart';

const _key = 'flutter.emoji.frequentlyUsed';

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
    String use(String id, int count, int day) =>
        '{"id":"$id","count":$count,"lastUsed":"2026-01-${day}T00:00:00.000"}';
    SharedPreferences.setMockInitialValues({
      _key: [
        use('u:old', 5, 10),
        for (var i = 0; i < 49; i++) use('u:$i', 1, 20),
      ].toString(),
    });
    final c = container();
    await c.read(frequentEmojisProvider.notifier).recordUse('u:new');

    final result = await ids(c);
    expect(result, hasLength(50));
    expect(result, isNot(contains('u:old')));
    expect(result, contains('u:new'));
  });

  test('ignores corrupt data', () async {
    SharedPreferences.setMockInitialValues({_key: 'not json'});
    expect(await ids(container()), isEmpty);

    SharedPreferences.setMockInitialValues({
      _key:
          '[{"id":"u:a","count":1,"lastUsed":"2026-01-01T00:00:00.000"},'
          '{"id":5}]',
    });
    expect(await ids(container()), ['u:a']);
  });
}
