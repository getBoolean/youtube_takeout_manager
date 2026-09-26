import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';

void main() {
  test('kinds keep the names saved queues were written with', () {
    expect(
      [for (final kind in QueueItemKind.values) kind.toValue()],
      ['comment', 'liveChat'],
    );
    expect(QueueItemKindMapper.fromValue('liveChat'), QueueItemKind.liveChat);
  });
}
