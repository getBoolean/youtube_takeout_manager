import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';

void main() {
  const statuses = InteractionStatuses(
    deleted: {'deleted', 'everything'},
    failed: {'failed', 'everything', 'failed-and-queued'},
    queued: {'queued', 'everything', 'failed-and-queued'},
  );

  test('an item in several sets shows its most final status', () {
    expect(statuses.of('everything'), InteractionStatus.deleted);
    expect(statuses.of('failed-and-queued'), InteractionStatus.failed);
    expect(statuses.of('queued'), InteractionStatus.queued);
    expect(statuses.of('untouched'), InteractionStatus.active);
  });

  test('only active items can be picked for deletion', () {
    expect(
      [
        for (final s in InteractionStatus.values)
          if (s.isSelectable) s,
      ],
      [InteractionStatus.active],
    );
    expect(statuses.unselectableIds, {
      'deleted',
      'everything',
      'failed',
      'failed-and-queued',
      'queued',
    });
  });

  test('the status labels the text next to the item, except when active', () {
    expect(InteractionStatus.deleted.labelled('May 1'), 'Deleted • May 1');
    expect(InteractionStatus.failed.labelled('May 1'), 'Failed • May 1');
    expect(InteractionStatus.queued.labelled('May 1'), 'Queued • May 1');
    expect(InteractionStatus.active.labelled('May 1'), 'May 1');
  });
}
