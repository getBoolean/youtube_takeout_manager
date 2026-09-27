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
    for (final status in InteractionStatus.values) {
      if (status == InteractionStatus.active) continue;
      expect(
        status.labelled('May 1'),
        allOf(contains(status.label!), contains('May 1')),
        reason: status.name,
      );
    }
    expect(InteractionStatus.active.labelled('May 1'), 'May 1');
  });
}
