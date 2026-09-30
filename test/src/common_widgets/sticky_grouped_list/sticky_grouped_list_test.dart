import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';

const _headerHeight = 50.0;
const _itemHeight = 40.0;

typedef _Group = ({String key, List<String> items});

List<_Group> _groups(int count, int itemsPerGroup) => [
  for (var g = 0; g < count; g++)
    (key: 'g$g', items: [for (var i = 0; i < itemsPerGroup; i++) 'g$g-i$i']),
];

/// Per-group header state that records how the list drives it.
class _HeaderState {
  _HeaderState(this.status);

  StickyHeaderStatus status;
  final updates = <StickyHeaderStatus>[];
  final updatePhases = <SchedulerPhase>[];
  bool disposed = false;
}

class _Harness {
  _Harness([StickyGroupedListController? controller])
    : controller = controller ?? StickyGroupedListController();

  final ScrollController scroll = ScrollController();
  final StickyGroupedListController controller;
  final created = <String, _HeaderState>{};
  final disposed = <String>[];
  final headerBuilds = <String>[];
  final itemBuilds = <String>[];

  /// How many times the list asked for an item's key.
  int itemKeyLookups = 0;

  /// Header states passed to each built header, keyed by group.
  final statesSeen = <String, Set<_HeaderState>>{};

  void dispose() {
    scroll.dispose();
    controller.dispose();
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required List<_Group> groups,
  (int, int)? Function(Object itemKey)? locateItem,
  StickyGroupedListController? controller,
}) async {
  tester.view.physicalSize = const Size(400, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final h = _Harness(controller);
  addTearDown(h.dispose);

  await tester.pumpWidget(_app(h, groups, locateItem: locateItem));
  return h;
}

Widget _app(
  _Harness h,
  List<_Group> groups, {
  (int, int)? Function(Object itemKey)? locateItem,
}) => MaterialApp(
  home: Scaffold(
    body: StickyGroupedListView<_Group, String, _HeaderState>(
      groups: groups,
      groupKey: (group) => group.key,
      itemsOf: (group) => group.items,
      itemKey: (item) {
        h.itemKeyLookups++;
        return item;
      },
      locateItem: locateItem,
      controller: h.controller,
      scrollController: h.scroll,
      createHeaderState: (group, status, vsync) =>
          h.created[group.key] = _HeaderState(status),
      updateHeaderState: (group, state, status) {
        state
          ..status = status
          ..updates.add(status)
          ..updatePhases.add(SchedulerBinding.instance.schedulerPhase);
      },
      disposeHeaderState: (state) {
        state.disposed = true;
        h.disposed.add(
          h.created.entries.firstWhere((e) => e.value == state).key,
        );
      },
      headerBuilder: (context, group, state, status) {
        h.headerBuilds.add(group.key);
        h.statesSeen.putIfAbsent(group.key, () => {}).add(state);
        return GestureDetector(
          onTap: () => h.controller.toggle(group.key),
          child: Container(
            height: _headerHeight,
            color: Colors.blue,
            child: Text('header ${group.key}'),
          ),
        );
      },
      itemBuilder: (context, group, item, index) {
        h.itemBuilds.add(item);
        return SizedBox(height: _itemHeight, child: Text(item));
      },
    ),
  ),
);

Finder _header(String key) => find.text('header $key').hitTestable();

void main() {
  testWidgets('only builds rows near the viewport', (tester) async {
    final h = await _pump(tester, groups: _groups(200, 20));
    // 600px viewport + 250px cache: about 21 rows of 40px.
    expect(h.itemBuilds.length, lessThan(30));
    expect(h.headerBuilds.toSet().length, lessThan(6));

    // Let the post-layout status rebuild settle before counting again.
    await tester.pump();
    h.headerBuilds.clear();
    h.itemBuilds.clear();
    h.scroll.jumpTo(50000);
    await tester.pump();
    expect(h.itemBuilds.length, lessThan(30));
    // Landed on the right rows: g58 starts at 58 * 850 = 49300.
    expect(find.text('g58-i17').hitTestable(), findsOneWidget);
    expect(h.headerBuilds.toSet().length, lessThan(8));
  });

  testWidgets('pins the header of the group at the top', (tester) async {
    final h = await _pump(tester, groups: _groups(5, 20));
    expect(h.created['g0']!.status.isPinned, isFalse);

    h.scroll.jumpTo(30);
    await tester.pump();
    expect(_header('g0'), findsOneWidget);
    expect(tester.getTopLeft(_header('g0')).dy, 0);
    expect(h.created['g0']!.status.isPinned, isTrue);
    expect(h.controller.pinnedGroupKey, 'g0');
  });

  testWidgets('the next header pushes the pinned one up', (tester) async {
    final h = await _pump(tester, groups: _groups(5, 20));
    const groupExtent = _headerHeight + 20 * _itemHeight;
    h.scroll.jumpTo(groupExtent - _headerHeight + 10);
    await tester.pump();
    expect(tester.getTopLeft(_header('g0')).dy, -10);
    expect(tester.getTopLeft(_header('g1')).dy, _headerHeight - 10);
    expect(h.created['g0']!.status.scrollPercentage, closeTo(0.2, 1e-9));
  });

  testWidgets('updates header state during layout of the same frame', (
    tester,
  ) async {
    final h = await _pump(tester, groups: _groups(5, 20));
    final state = h.created['g0']!;
    state.updates.clear();
    state.updatePhases.clear();

    h.scroll.jumpTo(30);
    await tester.pump();
    expect(state.updates.map((s) => s.isPinned), contains(isTrue));
    expect(
      state.updatePhases,
      everyElement(SchedulerPhase.persistentCallbacks),
    );
  });

  testWidgets('shares one header state between the row and its pinned copy', (
    tester,
  ) async {
    final h = await _pump(tester, groups: _groups(5, 20));
    h.scroll.jumpTo(30);
    await tester.pump();
    await tester.pump();
    for (final states in h.statesSeen.values) {
      expect(states, hasLength(1));
    }
    expect(h.created.keys.toSet(), h.statesSeen.keys.toSet());
  });

  testWidgets('disposes header states that scroll away and on dispose', (
    tester,
  ) async {
    final h = await _pump(tester, groups: _groups(100, 20));
    expect(h.created, contains('g0'));

    h.scroll.jumpTo(20000);
    await tester.pump();
    await tester.pump();
    expect(h.disposed, contains('g0'));
    expect(h.created['g0']!.disposed, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(h.created.values.where((s) => !s.disposed), isEmpty);
  });

  testWidgets('collapses and expands instantly', (tester) async {
    final h = await _pump(tester, groups: _groups(5, 3));
    expect(find.text('g1-i0'), findsOneWidget);

    await tester.tap(_header('g1'));
    await tester.pump();
    expect(find.text('g1-i0'), findsNothing);
    expect(h.controller.isExpanded('g1'), isFalse);
    expect(h.created['g1']!.status.isExpanded, isFalse);

    await tester.tap(_header('g1'));
    await tester.pump();
    expect(find.text('g1-i0'), findsOneWidget);
  });

  testWidgets('a list can start with every group collapsed, and a tap opens '
      'one', (tester) async {
    final h = await _pump(
      tester,
      groups: _groups(5, 3),
      controller: StickyGroupedListController(expandedByDefault: false),
    );
    expect(_header('g1'), findsOneWidget);
    expect(find.text('g1-i0'), findsNothing);

    await tester.tap(_header('g1'));
    await tester.pump();

    expect(find.text('g1-i0'), findsOneWidget);
    expect(find.text('g2-i0'), findsNothing);
    expect(h.controller.isExpanded('g1'), isTrue);
  });

  testWidgets('collapsing every group also collapses groups added later', (
    tester,
  ) async {
    final h = await _pump(tester, groups: _groups(3, 3));

    h.controller.setAllExpanded(false);
    await tester.pumpWidget(_app(h, _groups(8, 3)));

    expect(_header('g6'), findsOneWidget);
    expect(find.text('g0-i0'), findsNothing);
    expect(find.text('g6-i0'), findsNothing);
  });

  testWidgets('expanding every group opens ones collapsed one by one', (
    tester,
  ) async {
    final h = await _pump(tester, groups: _groups(5, 3));
    h.controller
      ..setExpanded('g0', false)
      ..setExpanded('g1', false);
    await tester.pump();
    expect(find.text('g0-i0'), findsNothing);

    h.controller.setAllExpanded(true);
    await tester.pump();

    expect(find.text('g0-i0'), findsOneWidget);
    expect(find.text('g1-i0'), findsOneWidget);
  });

  testWidgets('expanding some groups opens just those', (tester) async {
    final h = await _pump(
      tester,
      groups: _groups(5, 3),
      controller: StickyGroupedListController(expandedByDefault: false),
    );

    h.controller.expandAll(['g0', 'g2']);
    await tester.pump();

    expect(find.text('g0-i0'), findsOneWidget);
    expect(find.text('g1-i0'), findsNothing);
    expect(find.text('g2-i0'), findsOneWidget);
  });

  testWidgets('reveals an item that was never laid out below its header', (
    tester,
  ) async {
    final h = await _pump(tester, groups: _groups(100, 20));
    final revealed = h.controller.revealItem(
      'g60-i5',
      gap: 12,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    await tester.pumpAndSettle();
    expect(await revealed, isTrue);
    expect(tester.getTopLeft(find.text('g60-i5')).dy, _headerHeight + 12);
    expect(tester.getTopLeft(_header('g60')).dy, 0);
  });

  testWidgets(
    'a far jump in a 100,000-row list lands on its row, looking up only '
    'rows near it',
    (tester) async {
      final h = await _pump(tester, groups: _groups(1000, 100));
      await tester.pump();
      h.itemKeyLookups = 0;

      // Each group is 50 + 100 * 40 = 4050px, so g700-i37 starts here.
      h.scroll.jumpTo(700 * 4050 + _headerHeight + 37 * _itemHeight);
      await tester.pump();
      await tester.pump();

      // i37 and i38 are under the pinned header.
      expect(tester.getTopLeft(find.text('g700-i39')).dy, 2 * _itemHeight);
      expect(_header('g700'), findsOneWidget);
      expect(h.itemKeyLookups, lessThan(2000));
    },
  );

  testWidgets('reveals a far item in a 100,000-row list', (tester) async {
    final h = await _pump(tester, groups: _groups(1000, 100));
    final revealed = h.controller.revealItem(
      'g900-i50',
      gap: 12,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    await tester.pumpAndSettle();
    expect(await revealed, isTrue);
    expect(tester.getTopLeft(find.text('g900-i50')).dy, _headerHeight + 12);
  });

  testWidgets('tells which group is at the top, pinned or not', (tester) async {
    final h = await _pump(tester, groups: _groups(100, 20));
    expect(h.controller.topGroupKey, 'g0');

    // Each group is 50 + 20 * 40 = 850px: g5's header right at the top.
    h.scroll.jumpTo(5 * 850);
    await tester.pump();
    expect(h.controller.topGroupKey, 'g5');

    h.scroll.jumpTo(5 * 850 + 300);
    await tester.pump();
    expect(h.controller.topGroupKey, 'g5');
    expect(h.controller.pinnedGroupKey, 'g5');
  });

  testWidgets(
    'given where items are, new groups find their rows without walking '
    'every item',
    (tester) async {
      final groups = _groups(1000, 100);
      (int, int)? locate(Object key) {
        final [g, i] = (key as String).substring(1).split('-i');
        return (int.parse(g), int.parse(i));
      }

      final h = await _pump(tester, groups: groups, locateItem: locate);
      h.scroll.jumpTo(700 * 4050);
      await tester.pump();
      h.itemKeyLookups = 0;

      // The same groups in a new list, as a new search result would be.
      await tester.pumpWidget(_app(h, [...groups], locateItem: locate));

      expect(h.itemKeyLookups, lessThan(2000));
      expect(find.text('g700-i10'), findsOneWidget);
    },
  );

  test('only depends on Flutter', () {
    final dir = Directory('lib/src/common_widgets/sticky_grouped_list');
    final imports = [
      for (final file in dir.listSync(recursive: true).whereType<File>())
        for (final line in file.readAsLinesSync())
          if (line.startsWith('import ')) line,
    ];
    expect(imports, isNotEmpty);
    for (final line in imports) {
      expect(
        line,
        anyOf(
          startsWith("import 'package:flutter/"),
          startsWith("import 'dart:"),
          startsWith("import 'src/"),
        ),
      );
    }
  });
}
