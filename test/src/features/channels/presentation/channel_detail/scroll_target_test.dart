import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/channel_detail_screen.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';

void main() {
  test("the route's target kind names the item's kind", () {
    expect(parseScrollTarget('comment', 'c1'), (
      kind: QueueItemKind.comment,
      id: 'c1',
    ));
    expect(parseScrollTarget('liveChat', 'l1'), (
      kind: QueueItemKind.liveChat,
      id: 'l1',
    ));
  });

  test('without a known kind and an ID there is no target', () {
    expect(parseScrollTarget(null, 'c1'), isNull);
    expect(parseScrollTarget('comment', null), isNull);
    expect(parseScrollTarget('video', 'c1'), isNull);
  });
}
