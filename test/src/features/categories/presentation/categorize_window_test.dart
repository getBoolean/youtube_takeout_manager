import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorization_progress.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/pending_ai_work.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/run_estimate.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/ai_keys_setup.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/categorize_window.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/tag_pages.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_grouping.dart';
import 'package:youtube_takeout_manager/src/features/history/presentation/history_toolbar.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

/// Runs nothing: counts what it's asked to do, and says it runs while it
/// does.
class _Categorizer extends ChannelCategorizer {
  var runs = 0;
  var stops = 0;

  @override
  void build() {}

  @override
  void run() {
    runs++;
    ref.read(categorizationProgressProvider.notifier).start(120, ai: true);
  }

  @override
  void stop() {
    stops++;
    ref.read(categorizationProgressProvider.notifier).stopping();
  }
}

class _Pending extends PendingAiWork {
  _Pending(this.summary);

  final AiWorkSummary? summary;

  @override
  AiWorkSummary? build() => summary;
}

const _work = AiWorkSummary(
  categorize: 1204,
  redo: 37,
  tags: 512,
  checks: 9800,
  uncategorized: 41,
  evidenceChars: [2000, 2000, 2000],
  checkChars: [1000],
);

/// Opens the Categorize window from History's toolbar, with [keys], what a
/// run would do being [summary], and [tags] kept.
Future<(ProviderContainer, _Categorizer)> _open(
  WidgetTester tester, {
  AiKeys keys = const AiKeys(typesafe: 'jv_live_1', anthropic: 'sk-ant-1'),
  AiWorkSummary? summary = _work,
  Map<String, TagName> tags = const {},
  Map<String, ChannelCategory> categories = const {},
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final categorizer = _Categorizer();
  final container = ProviderContainer(
    overrides: [
      channelCategorizerProvider.overrideWith(() => categorizer),
      pendingAiWorkProvider.overrideWith(() => _Pending(summary)),
      aiKeysProvider.overrideWith((ref) async => keys),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  for (final MapEntry(:key, :value) in tags.entries) {
    await container.read(tagNamesProvider.notifier).put(key, value);
  }
  if (categories.isNotEmpty) {
    await container.read(channelCategoriesProvider.future);
    await container
        .read(channelCategoriesProvider.notifier)
        .replaceAll(categories);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => HistoryToolbar(
              grouping: HistoryGrouping.channel,
              activeFilters: 0,
              onGroupBy: () {},
              onFilters: () {},
              onCollapseAll: () {},
              onExpandAll: () {},
              onCategorize: () => showCategorizeWindow(context),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(HistoryToolbar.categorizeKey));
  await tester.pumpAndSettle();
  return (container, categorizer);
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _toRun(WidgetTester tester) =>
    _tapKey(tester, CategorizeWindow.nextKey);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets("History's Categorize button shows the magic wand, and opens "
      'the window on the tags, then Run', (tester) async {
    await _open(tester);

    expect(
      find.descendant(
        of: find.byKey(HistoryToolbar.categorizeKey),
        matching: find.byIcon(Icons.auto_fix_high),
      ),
      findsOneWidget,
    );
    expect(find.byKey(TagsPage.defineKey), findsOneWidget);

    await _toRun(tester);
    expect(find.byKey(CategorizeWindow.runKey), findsOneWidget);
  });

  group('your tags', () {
    testWidgets('a tag defined with a meaning is the user\'s, and checked '
        'for on the next run', (tester) async {
      final (container, _) = await _open(tester);

      await _tapKey(tester, TagsPage.defineKey);
      await tester.enterText(find.byKey(TagForm.nameKey), 'Loli/Lolicon');
      await tester.enterText(
        find.byKey(TagForm.meaningKey),
        'Anime art of childlike characters',
      );
      await _tapKey(tester, TagForm.saveKey);

      final tag = (await container.read(
        tagNamesProvider.future,
      ))['lolilolicon'];
      expect(tag?.origin, NameOrigin.user);
      expect(tag?.meaning, 'Anime art of childlike characters');
      expect(tag?.changedAt, isNotNull);
      expect(find.byKey(TagsPage.rowKey('lolilolicon')), findsOneWidget);
    });

    testWidgets("changing an AI-named tag's meaning makes it the user's", (
      tester,
    ) async {
      final (container, _) = await _open(
        tester,
        tags: {'asmr': const TagName(name: 'ASMR', meaning: 'Whispers')},
      );

      await _tapKey(tester, TagsPage.rowKey('asmr'));
      await tester.enterText(
        find.byKey(TagForm.meaningKey),
        'Relaxing sounds and whispers',
      );
      await _tapKey(tester, TagForm.saveKey);

      final tag = (await container.read(tagNamesProvider.future))['asmr'];
      expect(tag?.origin, NameOrigin.user);
      expect(tag?.meaning, 'Relaxing sounds and whispers');
    });

    testWidgets('deleting a tag asks first, in place, then takes it off '
        'every channel', (tester) async {
      final (container, _) = await _open(
        tester,
        tags: {'asmr': const TagName(name: 'ASMR')},
        categories: {
          'UCa': ChannelCategory(
            tags: const ['ASMR'],
            tagsTried: true,
            decidedAt: DateTime.utc(2026, 10, 1),
          ),
        },
      );

      await _tapKey(tester, TagsPage.rowKey('asmr'));
      await _tapKey(tester, TagForm.deleteKey);
      expect(
        (await container.read(tagNamesProvider.future))['asmr']?.deleted,
        isFalse,
      );
      await _tapKey(tester, TagForm.confirmDeleteKey);

      expect(
        (await container.read(tagNamesProvider.future))['asmr']?.deleted,
        isTrue,
      );
      expect(
        (await container.read(channelCategoriesProvider.future))['UCa']?.tags,
        isEmpty,
      );
      expect(find.byKey(TagsPage.rowKey('asmr')), findsNothing);
    });

    testWidgets('are found by name or by meaning', (tester) async {
      await _open(
        tester,
        tags: {
          'vtuberclips': const TagName(
            name: 'VTuber Clips',
            meaning: 'Clips of streams, made by someone else',
          ),
          'asmr': const TagName(name: 'ASMR'),
        },
      );

      await tester.enterText(find.byKey(TagsPage.searchKey), 'streams');
      await tester.pumpAndSettle();

      expect(find.byKey(TagsPage.rowKey('vtuberclips')), findsOneWidget);
      expect(find.byKey(TagsPage.rowKey('asmr')), findsNothing);
    });

    testWidgets('of 3,000, only those on screen are built', (tester) async {
      await _open(
        tester,
        tags: {
          for (var i = 0; i < 3000; i++)
            'tag$i': TagName(name: 'Tag $i', meaning: 'Meaning $i'),
        },
      );

      expect(find.byType(ListTile), findsWidgets);
      expect(tester.widgetList(find.byType(ListTile)).length, lessThan(100));
    });
  });

  group('Run', () {
    testWidgets('shows what a run would do and roughly what it would cost', (
      tester,
    ) async {
      await _open(tester);
      await _toRun(tester);

      for (final count in ['1,204', '37', '512', '9,800', '41']) {
        expect(find.textContaining(count), findsWidgets, reason: count);
      }
      expect(find.textContaining(r'$'), findsWidgets);
    });

    testWidgets('without keys, is locked, and opens the keys page, whose Back '
        'comes back to Run', (tester) async {
      final (_, categorizer) = await _open(tester, keys: AiKeys.none);
      await _toRun(tester);

      await _tapKey(tester, CategorizeWindow.runKey);
      expect(categorizer.runs, 0);
      expect(find.byKey(AiKeysForm.saveKey), findsOneWidget);
      expect(find.byKey(CategorizeWindow.runKey), findsNothing);

      await tester.tap(find.byTooltip('Back').last);
      await tester.pumpAndSettle();
      expect(find.byKey(CategorizeWindow.runKey), findsOneWidget);
    });

    testWidgets('starts a run, and while it goes, Stop stops it', (
      tester,
    ) async {
      final (_, categorizer) = await _open(tester);
      await _toRun(tester);

      await _tapKey(tester, CategorizeWindow.runKey);
      expect(categorizer.runs, 1);

      await _tapKey(tester, CategorizeWindow.stopKey);
      expect(categorizer.stops, 1);
    });

    testWidgets('with nothing to do, is off', (tester) async {
      final (_, categorizer) = await _open(
        tester,
        summary: const AiWorkSummary(
          categorize: 0,
          redo: 0,
          tags: 0,
          checks: 0,
          uncategorized: 0,
        ),
      );
      await _toRun(tester);

      await _tapKey(tester, CategorizeWindow.runKey);

      expect(categorizer.runs, 0);
    });
  });
}
