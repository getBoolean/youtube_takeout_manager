import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/video_group_header.dart';

import 'channel_list_fixture.dart';

/// Group headers are the expensive part of a channel's lists; only the ones
/// on screen (plus the pinnable copies around the top group) may be built.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  int builtHeaders() =>
      find.byType(VideoGroupHeader, skipOffstage: false).evaluate().length;

  for (final kind in ListKind.values) {
    testWidgets('builds only the headers near the viewport ($kind)', (
      tester,
    ) async {
      final h = await pumpList(tester, kind: kind);
      await tester.pumpAndSettle();
      // Three rows' worth on screen at the top plus up to three pinnable
      // copies; the sliver panels this replaced built fifteen.
      expect(builtHeaders(), lessThanOrEqualTo(7));

      await scrollTo(tester, h.scroll, 2000);
      await tester.pumpAndSettle();
      expect(builtHeaders(), lessThanOrEqualTo(8));
    });
  }
}
