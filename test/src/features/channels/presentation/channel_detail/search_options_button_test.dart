import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/search_options_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_options_state.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/search_options_button.dart';

class _FakeSearchOptions extends SearchOptions {
  _FakeSearchOptions(this._initial);
  final SearchOptionsState _initial;

  @override
  Future<SearchOptionsState> build() async => _initial;

  @override
  Future<void> setExpandMatchedVideos(bool value) async {
    state = AsyncData((await future).copyWith(expandMatchedVideos: value));
  }

  @override
  Future<void> setMatchGroupTitles(bool value) async {
    state = AsyncData((await future).copyWith(matchGroupTitles: value));
  }
}

void main() {
  Future<ProviderContainer> pumpButton(
    WidgetTester tester, {
    SearchOptionsState initial = const SearchOptionsState(),
  }) async {
    final container = ProviderContainer(
      overrides: [
        searchOptionsProvider.overrideWith(() => _FakeSearchOptions(initial)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(searchOptionsProvider.future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SearchOptionsButton())),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('tapping the button shows a dialog, not a menu', (tester) async {
    await pumpButton(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.byType(MenuAnchor), findsNothing);
    expect(find.text('Search options'), findsOneWidget);
    expect(find.text('Show all comments in matched videos'), findsOneWidget);
    expect(find.text('Match video titles'), findsOneWidget);
  });

  testWidgets('reflects the current options', (tester) async {
    await pumpButton(
      tester,
      initial: const SearchOptionsState(
        expandMatchedVideos: true,
        matchGroupTitles: false,
      ),
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final tiles = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(tiles[0].value, isTrue);
    expect(tiles[1].value, isFalse);
  });

  testWidgets('Done applies the changes', (tester) async {
    final container = await pumpButton(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show all comments in matched videos'));
    await tester.tap(find.text('Match video titles'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Search options'), findsNothing);
    final options = container.read(searchOptionsProvider).value!;
    expect(options.expandMatchedVideos, isTrue);
    expect(options.matchGroupTitles, isFalse);
  });

  testWidgets('Cancel discards the changes', (tester) async {
    final container = await pumpButton(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show all comments in matched videos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Search options'), findsNothing);
    final options = container.read(searchOptionsProvider).value!;
    expect(options.expandMatchedVideos, isFalse);
    expect(options.matchGroupTitles, isTrue);
  });
}
