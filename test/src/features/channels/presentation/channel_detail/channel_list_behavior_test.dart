import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_content_search_query.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/video_group_header.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';

import 'channel_list_fixture.dart';

Finder _header(String videoId) => find
    .byWidgetPredicate(
      (w) => w is VideoGroupHeader && w.group.videoId == videoId,
    )
    .hitTestable();

/// A comment tile of the fixture, found only while it's on screen.
Finder _comment(int group, int index) => find
    .textContaining('Comment $index in group $group', findRichText: true)
    .hitTestable();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('keeps the group header pinned while deep in its group', (
    tester,
  ) async {
    final h = await pumpList(tester);
    await tester.pumpAndSettle();
    await scrollTo(tester, h.scroll, 200);
    await tester.pumpAndSettle();

    expect(_header('v0'), findsOneWidget);
    expect(tester.getTopLeft(_header('v0')).dy, 0);
  });

  testWidgets('tapping a header collapses its group and tapping again '
      'expands it', (tester) async {
    await pumpList(tester);
    await tester.pumpAndSettle();
    expect(_comment(1, 0), findsOneWidget);

    await tester.tap(_header('v1'));
    await tester.pumpAndSettle();
    expect(_comment(1, 0), findsNothing);
    // Other groups stay open.
    expect(_comment(0, 0), findsOneWidget);

    await tester.tap(_header('v1'));
    await tester.pumpAndSettle();
    expect(_comment(1, 0), findsOneWidget);
  });

  testWidgets('long-pressing a header selects the whole group except what '
      "can't be deleted", (tester) async {
    final h = await pumpList(tester);
    await tester.pumpAndSettle();

    // Group 2's first comment is queued and its second failed.
    await tester.longPress(_header('v2'));
    await tester.pumpAndSettle();

    expect(h.selecting, isTrue);
    final group2 = commentGroups[2].items.map((c) => c.id).toSet();
    expect(h.container.read(deletionSetProvider), {
      ...group2.difference({commentId(2, 0), commentId(2, 1)}),
    });
  });

  testWidgets('long-pressing a header skips deleted items', (tester) async {
    final h = await pumpList(tester);
    await tester.pumpAndSettle();

    // Group 0's second comment is already deleted.
    await tester.longPress(_header('v0'));
    await tester.pumpAndSettle();

    expect(h.container.read(deletionSetProvider), {
      commentId(0, 0),
      commentId(0, 2),
    });
  });

  testWidgets('scrolls to the initial target', (tester) async {
    await pumpList(tester, initialScrollTarget: commentId(5, 7));
    expect(_comment(5, 7), findsNothing);

    await tester.pumpAndSettle();
    expect(_comment(5, 7), findsOneWidget);
  });

  testWidgets('changing the search scrolls back to the top', (tester) async {
    final h = await pumpList(tester);
    await tester.pumpAndSettle();
    await scrollTo(tester, h.scroll, 300);
    await tester.pumpAndSettle();
    expect(h.scroll.offset, greaterThan(0));

    h.container.read(channelContentSearchQueryProvider.notifier).update('1');
    await tester.pumpAndSettle();
    expect(h.scroll.offset, 0);
  });
}
