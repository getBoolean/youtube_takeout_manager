import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_emoji.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_change_pages.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_window.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

const _gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

class _Categorizer extends ChannelCategorizer {
  @override
  void build() {}

  @override
  bool get canAskAi => false;
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  Map<String, List<SubCategory>> custom = const {},
}) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      channelCategorizerProvider.overrideWith(_Categorizer.new),
      readSessionChannelIdProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  if (custom.isNotEmpty) {
    await container.read(customCategoriesProvider.future);
    await container.read(customCategoriesProvider.notifier).replaceAll(custom);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showCategoryWindow(context, channel: _gamer),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(CategoryWindow.changeKey));
  await tester.pumpAndSettle();
  return container;
}

/// Taps [finder], scrolling the window to it first: its rows are built
/// only as they come on screen.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byWidgetPredicate((w) => w is WoltModalSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<ChannelCategory?> _kept(ProviderContainer c) async =>
    (await c.read(channelCategoriesProvider.future))['UCg'];

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('the rows to pick from', () {
    final parents = youtubeTaxonomy.parents.toList();

    test('are the categories, closed', () {
      expect(changeRows(youtubeTaxonomy), [
        for (final parent in parents) ChangeCategoryRow(parent),
      ]);
    });

    test('of a category opened are all of it, its sub-categories, and a '
        'new one', () {
      final rows = changeRows(youtubeTaxonomy, open: {'Entertainment'});

      final at = rows.indexOf(
        const ChangeCategoryRow('Entertainment', open: true),
      );
      expect(rows.sublist(at, at + 7), [
        const ChangeCategoryRow('Entertainment', open: true),
        const ChangeAllOfRow('Entertainment'),
        for (final child in youtubeTaxonomy.childrenOf('Entertainment'))
          ChangeSubRow('Entertainment', child),
        const ChangeNewSubRow('Entertainment'),
      ]);
    });

    test('searched, are the sub-categories that match, under their '
        'categories, opened', () {
      final rows = changeRows(youtubeTaxonomy, query: 'RACING');

      expect(rows, contains(const ChangeSubRow('Gaming', 'Racing')));
      expect(rows, contains(const ChangeCategoryRow('Gaming', open: true)));
      expect(rows, isNot(contains(const ChangeSubRow('Gaming', 'Puzzle'))));
    });

    test('a category searched for by name opens to all of it', () {
      final rows = changeRows(youtubeTaxonomy, query: 'society');

      expect(rows, contains(const ChangeSubRow('Society', 'Politics')));
    });

    test('closed, a category with many sub-categories is one row', () {
      final many = youtubeTaxonomy.withCustom({
        'Knowledge': [for (var i = 0; i < 300; i++) 'Topic $i'],
      });

      expect(changeRows(many), hasLength(parents.length));
    });
  });

  testWidgets('picking a sub-category makes it the channel\'s, as the user '
      'chose, and goes back', (tester) async {
    final container = await _open(tester);

    await _tap(tester, find.byKey(ChangePage.categoryKey('Gaming')));
    await _tap(tester, find.byKey(ChangePage.subKey('Gaming', 'Racing')));

    final kept = await _kept(container);
    expect(kept?.path, const CategoryPath('Gaming', 'Racing'));
    expect(kept?.source, CategorySource.user);
    expect(find.byKey(CategoryWindow.changeKey), findsOneWidget);
  });

  testWidgets('a category without a sub-category can be picked whole', (
    tester,
  ) async {
    final container = await _open(tester);

    await _tap(tester, find.byKey(ChangePage.categoryKey('Knowledge')));
    await _tap(tester, find.byKey(ChangePage.allOfKey('Knowledge')));

    expect((await _kept(container))?.path, const CategoryPath('Knowledge'));
  });

  testWidgets('a new sub-category typed in is kept with the emoji picked', (
    tester,
  ) async {
    final container = await _open(tester);

    await _tap(tester, find.byKey(ChangePage.categoryKey('Gaming')));
    await _tap(tester, find.byKey(ChangePage.newSubKey('Gaming')));
    await tester.enterText(find.byKey(NewSubCategoryPage.nameKey), 'Retro');
    await _tap(tester, find.byKey(NewSubCategoryPage.emojiKey));
    await tester.enterText(
      find.descendant(
        of: find.byKey(NewSubCategoryPage.pickerKey),
        matching: find.byType(TextField),
      ),
      'fire',
    );
    await tester.pump();
    await _tap(tester, find.bySemanticsLabel(':fire:'));
    await _tap(tester, find.byKey(NewSubCategoryPage.addKey));

    expect(
      (await _kept(container))?.path,
      const CategoryPath('Gaming', 'Retro'),
    );
    expect((await container.read(customCategoriesProvider.future))['Gaming'], [
      const SubCategory(name: 'Retro', origin: NameOrigin.user, emoji: '🔥'),
    ]);
  });

  testWidgets("a new sub-category with no emoji picked shows its category's", (
    tester,
  ) async {
    final container = await _open(tester);

    await _tap(tester, find.byKey(ChangePage.categoryKey('Gaming')));
    await _tap(tester, find.byKey(ChangePage.newSubKey('Gaming')));
    await tester.enterText(find.byKey(NewSubCategoryPage.nameKey), 'Retro');
    await _tap(tester, find.byKey(NewSubCategoryPage.addKey));

    final emojiOf = container.read(categoryEmojiOfProvider);
    expect(
      emojiOf(const CategoryPath('Gaming', 'Retro')),
      categoryEmoji['Gaming'],
    );
  });

  testWidgets('a new name that folds into one AI made picks that one, still '
      'AI-made', (tester) async {
    final container = await _open(
      tester,
      custom: {
        'Gaming': [const SubCategory(name: 'Speedruns')],
      },
    );

    await _tap(tester, find.byKey(ChangePage.categoryKey('Gaming')));
    await _tap(tester, find.byKey(ChangePage.newSubKey('Gaming')));
    await tester.enterText(
      find.byKey(NewSubCategoryPage.nameKey),
      'speed-runs',
    );
    await _tap(tester, find.byKey(NewSubCategoryPage.addKey));

    expect(
      (await _kept(container))?.path,
      const CategoryPath('Gaming', 'Speedruns'),
    );
    expect((await container.read(customCategoriesProvider.future))['Gaming'], [
      const SubCategory(name: 'Speedruns'),
    ]);
  });

  testWidgets('a category with hundreds of sub-categories builds only the '
      'rows on screen', (tester) async {
    await _open(
      tester,
      custom: {
        'Knowledge': [
          for (var i = 0; i < 300; i++) SubCategory(name: 'Topic $i'),
        ],
      },
    );

    await _tap(tester, find.byKey(ChangePage.categoryKey('Knowledge')));

    expect(find.byType(ListTile).evaluate().length, lessThan(100));
  });
}
