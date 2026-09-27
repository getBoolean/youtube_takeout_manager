import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [viewedChannelIdProvider.overrideWithValue('UCme')],
    );
    addTearDown(c.dispose);
    c.listen(deletionSetProvider, (_, _) {});
    return c;
  }

  group('toggling a group', () {
    test('picks its eligible items', () {
      final c = container();

      c
          .read(deletionSetProvider.notifier)
          .toggleGroup({'a', 'b', 'queued'}, ineligibleIds: {'queued'});

      expect(c.read(deletionSetProvider), {'a', 'b'});
    });

    test('picks the rest when only some are picked', () {
      final c = container();
      final set = c.read(deletionSetProvider.notifier)..addAll({'a', 'other'});

      set.toggleGroup({'a', 'b'}, ineligibleIds: const {});

      expect(c.read(deletionSetProvider), {'a', 'b', 'other'});
    });

    test('drops them once all are picked, leaving other items', () {
      final c = container();
      final set = c.read(deletionSetProvider.notifier)
        ..addAll({'a', 'b', 'other'});

      set.toggleGroup({'a', 'b', 'queued'}, ineligibleIds: {'queued'});

      expect(c.read(deletionSetProvider), {'other'});
    });

    test('does nothing when none are eligible', () {
      final c = container();

      c
          .read(deletionSetProvider.notifier)
          .toggleGroup({'queued'}, ineligibleIds: {'queued'});

      expect(c.read(deletionSetProvider), isEmpty);
    });
  });
}
