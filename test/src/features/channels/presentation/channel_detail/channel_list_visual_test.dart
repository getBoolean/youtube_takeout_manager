// Golden baseline for the channel detail comment and live chat lists.
//
// Recorded against the sliver_sticky_collapsable_panel implementation so any
// reimplementation of the lists must look and animate identically. Scrolling
// uses small per-frame steps (see `scrollTo`) like real wheel/drag input.
//
// Regenerate only on an intentional UI change:
// flutter test --update-goldens test/src/features/channels/presentation/channel_detail/channel_list_visual_test.dart
import 'package:flutter/material.dart';
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

Future<void> _golden(String name) =>
    expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/$name.png'));

/// Captures the current frame, one frame later, 100ms in, and once settled.
Future<void> _frames(WidgetTester tester, String name) async {
  await tester.pump();
  await _golden('${name}_0');
  await tester.pump(const Duration(milliseconds: 16));
  await _golden('${name}_1f');
  await tester.pump(const Duration(milliseconds: 84));
  await _golden('${name}_100ms');
  await tester.pumpAndSettle();
  await _golden('${name}_settled');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('comment list', () {
    testWidgets('initial', (tester) async {
      await pumpList(tester);
      await tester.pumpAndSettle();
      await _golden('comments_initial');
    });

    testWidgets('pins and morphs the first header', (tester) async {
      final h = await pumpList(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, h.scroll, 20);
      await _frames(tester, 'comments_pin');
    });

    testWidgets('deep inside the first group', (tester) async {
      final h = await pumpList(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, h.scroll, 200);
      await tester.pumpAndSettle();
      await _golden('comments_deep');
      expect(_header('v0'), findsOneWidget);
      expect(tester.getTopLeft(_header('v0')).dy, 0);
    });

    testWidgets('next header pushes the pinned one up', (tester) async {
      final h = await pumpList(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, h.scroll, 300);
      await tester.pumpAndSettle();
      await _golden('comments_push_up');
    });

    testWidgets('hands off to the next group and back', (tester) async {
      final h = await pumpList(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, h.scroll, 330);
      await _frames(tester, 'comments_handoff');
      await scrollTo(tester, h.scroll, 0);
      await _frames(tester, 'comments_unpin');
    });

    testWidgets('collapses and expands from the in-list header', (
      tester,
    ) async {
      await pumpList(tester);
      await tester.pumpAndSettle();
      expect(
        find
            .textContaining('Comment 0 in group 1,', findRichText: true)
            .hitTestable(),
        findsOneWidget,
      );
      await tester.tap(_header('v1'));
      await _frames(tester, 'comments_collapse');
      expect(
        find
            .textContaining('Comment 0 in group 1,', findRichText: true)
            .hitTestable(),
        findsNothing,
      );
      await tester.tap(_header('v1'));
      await _frames(tester, 'comments_expand');
      expect(
        find
            .textContaining('Comment 0 in group 1,', findRichText: true)
            .hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('collapses the pinned group', (tester) async {
      final h = await pumpList(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, h.scroll, 200);
      await tester.pumpAndSettle();
      await tester.tap(_header('v0'));
      await _frames(tester, 'comments_collapse_pinned');
    });

    testWidgets('long-press enters selection mode', (tester) async {
      final h = await pumpList(tester);
      await tester.pumpAndSettle();
      await tester.longPress(_header('v1'));
      await _frames(tester, 'comments_selection');
      expect(h.selecting, isTrue);
      expect(
        h.container.read(deletionSetProvider),
        containsAll([commentId(1, 0)]),
      );
    });

    testWidgets('scrolls to and highlights the initial target', (tester) async {
      await pumpList(tester, initialScrollTarget: commentId(5, 7));
      await _golden('comments_target_0');
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 150));
      await _golden('comments_target_mid_scroll');
      await tester.pump(const Duration(milliseconds: 300));
      await _golden('comments_target_scrolled');
      await tester.pump(const Duration(milliseconds: 400));
      await _golden('comments_target_mid_highlight');
      await tester.pumpAndSettle();
      await _golden('comments_target_settled');
    });

    testWidgets('search change resets to the top', (tester) async {
      final h = await pumpList(tester);
      await tester.pumpAndSettle();
      await scrollTo(tester, h.scroll, 300);
      await tester.pumpAndSettle();
      h.container.read(channelContentSearchQueryProvider.notifier).update('1');
      await _frames(tester, 'comments_search_reset');
      expect(h.scroll.offset, 0);
    });
  });

  group('live chat list', () {
    testWidgets('initial and pinned', (tester) async {
      final h = await pumpList(tester, kind: ListKind.liveChats);
      await tester.pumpAndSettle();
      await _golden('live_chats_initial');
      await scrollTo(tester, h.scroll, 500);
      await _frames(tester, 'live_chats_pinned');
    });
  });
}
