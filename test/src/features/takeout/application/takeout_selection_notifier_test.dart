import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(takeoutSelectionProvider, (_, _) {});
    return c;
  }

  test('starts from the saved takeout and the channel viewed in it', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.active_takeout_account': 'UCa',
      'flutter.viewed_takeout_channel:UCa': 'UCa2',
    });

    expect(
      await container().read(takeoutSelectionProvider.future),
      const TakeoutSelection(takeoutId: 'UCa', channelId: 'UCa2'),
    );
  });

  test('starts with nothing selected', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await container().read(takeoutSelectionProvider.future), isNull);
  });

  test('remembers the channel viewed in each takeout', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(takeoutSelectionProvider.future);
    final notifier = c.read(takeoutSelectionProvider.notifier);

    await notifier.select('UCa', channelId: 'UCa2');
    await notifier.select('UCb');
    expect(
      c.read(takeoutSelectionProvider).value,
      const TakeoutSelection(takeoutId: 'UCb'),
    );

    await notifier.select('UCa');
    expect(
      c.read(takeoutSelectionProvider).value,
      const TakeoutSelection(takeoutId: 'UCa', channelId: 'UCa2'),
    );
    // And after a restart.
    expect(
      await container().read(takeoutSelectionProvider.future),
      const TakeoutSelection(takeoutId: 'UCa', channelId: 'UCa2'),
    );
  });

  test('changing channel keeps the takeout and is remembered', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.active_takeout_account': 'UCa',
    });
    final c = container();
    await c.read(takeoutSelectionProvider.future);

    await c.read(takeoutSelectionProvider.notifier).selectChannel('UCa2');

    const expected = TakeoutSelection(takeoutId: 'UCa', channelId: 'UCa2');
    expect(c.read(takeoutSelectionProvider).value, expected);
    expect(await container().read(takeoutSelectionProvider.future), expected);
  });

  test('the last of several quick switches wins, on disk too', () async {
    SharedPreferences.setMockInitialValues({});
    final c = container();
    await c.read(takeoutSelectionProvider.future);
    final notifier = c.read(takeoutSelectionProvider.notifier);

    final switches = [
      notifier.select('UCa'),
      notifier.select('UCb'),
      notifier.select('UCc', channelId: 'UCc2'),
    ];
    await Future.wait(switches);

    const expected = TakeoutSelection(takeoutId: 'UCc', channelId: 'UCc2');
    expect(c.read(takeoutSelectionProvider).value, expected);
    expect(await container().read(takeoutSelectionProvider.future), expected);
  });

  test('clearing selects nothing, on disk too', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.active_takeout_account': 'UCa',
    });
    final c = container();
    await c.read(takeoutSelectionProvider.future);

    await c.read(takeoutSelectionProvider.notifier).clear();

    expect(c.read(takeoutSelectionProvider).value, isNull);
    expect(await container().read(takeoutSelectionProvider.future), isNull);
  });
}
