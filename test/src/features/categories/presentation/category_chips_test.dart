import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_tiers.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorization_progress.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_emoji.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/categorization_banner.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_chips.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_colors.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_sheet.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel_details.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

class _Categories extends ChannelCategories {
  _Categories(this.categories);

  final Map<String, ChannelCategory> categories;

  @override
  Future<Map<String, ChannelCategory>> build() async => categories;
}

class _Details extends ChannelDetailsNotifier {
  @override
  Future<Map<String, ChannelDetails>> build() async => {
    'UCg': const ChannelDetails(
      topicUrls: ['https://en.wikipedia.org/wiki/Action_game'],
    ),
  };
}

class _Progress extends CategorizationProgress {
  @override
  ({bool running, int done, int total, bool redo}) build() =>
      (running: true, done: 3, total: 12, redo: false);
}

const _gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

ChannelCategory _category({
  CategoryPath? path = const CategoryPath('Gaming', 'Action'),
  CategorySource source = CategorySource.youtube,
  List<String> tags = const [],
}) => ChannelCategory(
  path: path,
  source: source,
  hadTopics: true,
  tags: tags,
  tagsTried: tags.isNotEmpty,
  decidedAt: DateTime.utc(2026, 9, 30),
);

Future<void> _pump(
  WidgetTester tester, {
  Map<String, ChannelCategory> categories = const {},
  Widget child = const ChannelCategoryChips(channel: _gamer),
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        channelCategoriesProvider.overrideWith(() => _Categories(categories)),
        channelDetailsProvider.overrideWith(_Details.new),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("a channel's category shows as a chip", (tester) async {
    await _pump(tester, categories: {'UCg': _category()});

    expect(
      find.textContaining(const CategoryPath('Gaming', 'Action').label),
      findsOneWidget,
    );
    expect(find.byType(AiMark), findsNothing);
    expect(find.text(categoryEmoji['Gaming']!), findsNothing);
    expect(
      find.text(youtubeSubCategoryEmoji['Gaming']!['Action']!),
      findsOneWidget,
    );
  });

  testWidgets('a category an AI chose is marked as such', (tester) async {
    await _pump(
      tester,
      categories: {'UCg': _category(source: CategorySource.claude)},
    );

    expect(find.byType(AiMark), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('AI')), findsOneWidget);
  });

  testWidgets('a channel not categorized yet has a chip too', (tester) async {
    await _pump(tester);

    expect(find.byKey(ChannelCategoryChips.tapKey), findsOneWidget);
    expect(find.text(uncategorizedEmoji), findsOneWidget);
  });

  testWidgets('a channel nothing could categorize says so', (tester) async {
    await _pump(tester, categories: {'UCg': _category(path: null)});

    expect(find.byKey(ChannelCategoryChips.tapKey), findsOneWidget);
    expect(find.text(uncategorizedEmoji), findsOneWidget);
  });

  testWidgets("a channel's tags show beside its category, and are told", (
    tester,
  ) async {
    await _pump(
      tester,
      categories: {
        'UCg': _category(tags: ['Mario Kart World', 'Speedruns']),
      },
    );

    expect(find.textContaining('Mario Kart World'), findsOneWidget);
    expect(find.textContaining('Speedruns'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Mario Kart World.*Speedruns')),
      findsOneWidget,
    );
  });

  testWidgets('nested under its category, a channel shows only its tags', (
    tester,
  ) async {
    await _pump(
      tester,
      categories: {
        'UCg': _category(tags: ['Speedruns']),
      },
      child: const ChannelCategoryChips(channel: _gamer, showCategory: false),
    );

    expect(find.textContaining('Speedruns'), findsOneWidget);
    expect(
      find.textContaining(const CategoryPath('Gaming', 'Action').label),
      findsNothing,
    );
  });

  testWidgets('the chip is easy to tap: at least 48 points tall', (
    tester,
  ) async {
    await _pump(tester, categories: {'UCg': _category()});

    expect(
      tester.getSize(find.byKey(ChannelCategoryChips.tapKey)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('tapping the chip opens it, not what it sits in', (tester) async {
    var outer = 0;
    await _pump(
      tester,
      categories: {'UCg': _category()},
      child: InkWell(
        onTap: () => outer++,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: ChannelCategoryChips(channel: _gamer),
        ),
      ),
    );

    await tester.tap(find.byKey(ChannelCategoryChips.tapKey));
    await tester.pumpAndSettle();

    expect(outer, 0);
    expect(find.byKey(CategorySheet.youtubeSourceKey), findsOneWidget);
  });

  testWidgets("tapping a YouTube category explains it comes from YouTube's "
      'topics for the channel', (tester) async {
    await _pump(tester, categories: {'UCg': _category()});

    await tester.tap(find.byKey(ChannelCategoryChips.tapKey));
    await tester.pumpAndSettle();

    expect(find.byKey(CategorySheet.youtubeSourceKey), findsOneWidget);
    expect(find.textContaining('Action game'), findsWidgets);
  });

  testWidgets("a YouTube category Jev checked says how sure Jev was", (
    tester,
  ) async {
    await _pump(
      tester,
      categories: {
        'UCg': ChannelCategory(
          path: const CategoryPath('Gaming', 'Action'),
          jevAgreed: 0.92,
          decidedAt: DateTime.utc(2026, 9, 30),
        ),
      },
    );

    await tester.tap(find.byKey(ChannelCategoryChips.tapKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('92%'), findsOneWidget);
  });

  testWidgets('a category Jev chose says how sure it was, and what came '
      'next', (tester) async {
    await _pump(
      tester,
      categories: {
        'UCg': ChannelCategory(
          path: const CategoryPath('Gaming', 'Speedruns'),
          source: CategorySource.jev,
          confidence: 0.81,
          runnersUp: const [
            ScoredPath(path: CategoryPath('Gaming', 'Action'), score: 0.12),
          ],
          decidedAt: DateTime.utc(2026, 9, 30),
        ),
      },
    );

    await tester.tap(find.byKey(ChannelCategoryChips.tapKey));
    await tester.pumpAndSettle();

    expect(find.byKey(CategorySheet.aiSourceKey), findsOneWidget);
    expect(find.textContaining('81%'), findsOneWidget);
    expect(
      find.textContaining(const CategoryPath('Gaming', 'Action').label),
      findsOneWidget,
    );
  });

  testWidgets('a notice about AI shows, and can be dismissed', (tester) async {
    await _pump(tester, child: const CategorizationBanner());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CategorizationBanner)),
    );

    container
        .read(aiTierStatusProvider.notifier)
        .disable(AiService.jev, 'Jev rejected its API key.');
    await tester.pumpAndSettle();
    expect(find.textContaining('Jev rejected'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jev rejected'), findsNothing);
    // Still off; only the notice goes.
    expect(container.read(aiTierStatusProvider).disabled, {AiService.jev});
  });

  testWidgets('while channels are categorized, how far along shows', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const CategorizationBanner(),
      overrides: [categorizationProgressProvider.overrideWith(_Progress.new)],
    );

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(3 / 12, 0.001));
  });

  testWidgets('once done, the progress goes away', (tester) async {
    await _pump(tester, child: const CategorizationBanner());

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
