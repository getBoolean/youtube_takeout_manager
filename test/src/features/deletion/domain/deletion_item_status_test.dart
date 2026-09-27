import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';

void main() {
  Set<DeletionItemStatus> where(bool Function(DeletionItemStatus) test) => {
    for (final s in DeletionItemStatus.values)
      if (test(s)) s,
  };

  test('items the quota stopped wait with the rest', () {
    expect(where((s) => s.isWaiting), {
      DeletionItemStatus.pending,
      DeletionItemStatus.inProgress,
      DeletionItemStatus.quotaExceeded,
    });
  });

  test('the next Delete takes waiting items not being deleted', () {
    expect(where((s) => s.isReadyToDelete), {
      DeletionItemStatus.pending,
      DeletionItemStatus.quotaExceeded,
    });
  });

  test('every status is waiting, failed or done', () {
    for (final s in DeletionItemStatus.values) {
      expect([s.isWaiting, s.isFailed, s.isDone].where((b) => b), hasLength(1));
    }
    expect(where((s) => s.isFailed), {DeletionItemStatus.failed});
    expect(where((s) => s.isDone), {DeletionItemStatus.succeeded});
  });
}
