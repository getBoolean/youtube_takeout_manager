import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_pane_expanded.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_placement.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_layout.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_pane.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_panel.dart';

class _EmptyQueue extends DeletionQueue {
  @override
  Future<List<DeletionQueueItem>> build() async => [];
}

void main() {
  DeletionQueueLayout layout(double width, TargetPlatform platform) =>
      deletionQueueLayoutFor(width: width, platform: platform);

  test('phones get the bottom bar', () {
    expect(
      layout(compactWidthBreakpoint / 2, TargetPlatform.android),
      DeletionQueueLayout.bottomBar,
    );
    expect(
      layout(compactWidthBreakpoint - 1, TargetPlatform.iOS),
      DeletionQueueLayout.bottomBar,
    );
  });

  test('desktop never gets the bottom bar', () {
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      const expanded = expandedWidthBreakpoint;
      const compact = compactWidthBreakpoint;
      expect(layout(expanded + 320, platform), DeletionQueueLayout.docked);
      expect(layout(expanded, platform), DeletionQueueLayout.docked);
      expect(layout(expanded - 1, platform), DeletionQueueLayout.strip);
      expect(layout(compact, platform), DeletionQueueLayout.strip);
      expect(layout(compact - 1, platform), DeletionQueueLayout.appBarIcon);
      expect(layout(compact / 2, platform), DeletionQueueLayout.appBarIcon);
    }
  });

  test('tablets use the desktop layouts', () {
    expect(
      layout(compactWidthBreakpoint, TargetPlatform.android),
      DeletionQueueLayout.strip,
    );
    expect(
      layout(expandedWidthBreakpoint, TargetPlatform.iOS),
      DeletionQueueLayout.docked,
    );
  });

  testWidgets('the side sheet hands over to the pane when the window widens', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [deletionQueueProvider.overrideWith(_EmptyQueue.new)],
    );
    addTearDown(container.dispose);
    // Collapsed beforehand, so the handover has to expand it.
    container.read(deletionQueuePaneExpandedProvider.notifier).set(false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final queue = DeletionQueuePlacement.of(context);
              return queue.wrap(
                Scaffold(appBar: AppBar(actions: queue.appBarActions)),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Deletion queue'));
    await tester.pumpAndSettle();
    expect(find.byType(DeletionQueuePanel), findsOneWidget);
    expect(find.byType(DeletionQueuePane), findsNothing);

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();

    // Only the docked pane's panel is left, expanded.
    expect(find.byType(DeletionQueuePanel), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DeletionQueuePane),
        matching: find.byType(DeletionQueuePanel),
      ),
      findsOneWidget,
    );
    expect(container.read(deletionQueuePaneExpandedProvider), isTrue);

    debugDefaultTargetPlatformOverride = null;
  });
}
