import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/data/credential_store.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_tiers.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/category_editor.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_keys_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/ai_keys_setup.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_chips.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_window.dart';
import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

const _gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

final _youtube = ChannelCategory(
  path: const CategoryPath('Gaming', 'Action'),
  hadTopics: true,
  decidedAt: DateTime.utc(2026, 9, 30),
);

final _suggestion = ChannelCategory(
  path: const CategoryPath('Gaming', 'Speedruns'),
  source: CategorySource.claude,
  reason: 'Races through games',
  decidedAt: DateTime.utc(2026, 9, 30),
);

/// Keeps what the user decided, and nothing else.
class _Editor extends CategoryEditor {
  final accepted = <ChannelCategory>[];
  var denied = 0;

  @override
  Future<void> accept(
    HistoryChannel channel,
    ChannelCategory suggestion,
  ) async => accepted.add(suggestion);

  @override
  Future<void> deny(HistoryChannel channel) async => denied++;
}

/// Asks no AI: suggests [suggestion], or fails with [failure] the first
/// [failures] times.
class _Categorizer extends ChannelCategorizer {
  _Categorizer({
    this.askable = true,
    this.failures = 0,
    this.hold,
    this.failure = const AiTierFailure(AiService.claude, AiOverloaded()),
  });

  final bool askable;
  int failures;
  final AiTierFailure failure;
  final Completer<void>? hold;
  var asked = 0;

  @override
  void build() {}

  @override
  bool get canAskAi => askable;

  @override
  Future<ChannelCategory> suggest(HistoryChannel channel) async {
    asked++;
    await hold?.future;
    if (failures > 0) {
      failures--;
      throw failure;
    }
    return _suggestion;
  }
}

class _Categories extends ChannelCategories {
  _Categories(this.categories);

  final Map<String, ChannelCategory> categories;

  @override
  Future<Map<String, ChannelCategory>> build() async => categories;
}

void main() {
  late _Categorizer categorizer;
  late _Editor editor;

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> open(
    WidgetTester tester, {
    ChannelCategory? category,
    _Categorizer? using,
  }) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    categorizer = using ?? _Categorizer();
    editor = _Editor();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelCategorizerProvider.overrideWith(() => categorizer),
          categoryEditorProvider.overrideWith(() => editor),
          channelCategoriesProvider.overrideWith(
            () => _Categories({'UCg': category ?? _youtube}),
          ),
          aiKeysRepositoryProvider.overrideWithValue(
            AiKeysRepository(CredentialStore(const FlutterSecureStorage())),
          ),
          aiTierStatusProvider.overrideWith(AiTierStatus.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(child: ChannelCategoryChips(channel: _gamer)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChannelCategoryChips.tapKey));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets("a YouTube category offers to ask AI, which suggests another; "
      "using it keeps it as the user's", (tester) async {
    await open(tester);

    await tapKey(tester, CategoryWindow.askAiKey);
    expect(find.textContaining(_suggestion.path!.label), findsWidgets);
    expect(find.textContaining('Races through games'), findsWidgets);
    // Each ask is paid for: once, however the modal builds the page.
    expect(categorizer.asked, 1);
    await tapKey(tester, CategoryAskPage.acceptKey);

    expect(editor.accepted, [_suggestion]);
    // Back in the window, where the category now shows.
    expect(find.byKey(CategoryWindow.changeKey), findsOneWidget);
  });

  testWidgets('keeping the current category says so, and nothing else '
      'changes', (tester) async {
    await open(tester);

    await tapKey(tester, CategoryWindow.askAiKey);
    await tapKey(tester, CategoryAskPage.denyKey);

    expect(editor.denied, 1);
    expect(editor.accepted, isEmpty);
  });

  testWidgets('while AI is asked, progress shows', (tester) async {
    final hold = Completer<void>();
    await open(tester, using: _Categorizer(hold: hold));

    await tester.tap(find.byKey(CategoryWindow.askAiKey));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(CategoryAskPage.progressKey), findsOneWidget);

    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(CategoryAskPage.progressKey), findsNothing);
    expect(find.byKey(CategoryAskPage.acceptKey), findsOneWidget);
  });

  testWidgets('a failed request says why in place, and can be tried again', (
    tester,
  ) async {
    await open(tester, using: _Categorizer(failures: 1));

    await tapKey(tester, CategoryWindow.askAiKey);
    expect(find.byKey(CategoryAskPage.failureKey), findsOneWidget);
    expect(find.byKey(CategoryAskPage.acceptKey), findsNothing);

    await tapKey(tester, CategoryAskPage.retryKey);
    expect(categorizer.asked, 2);
    expect(find.byKey(CategoryAskPage.acceptKey), findsOneWidget);
  });

  testWidgets('a request refused while the service asks to wait says when '
      'to try again', (tester) async {
    await open(
      tester,
      using: _Categorizer(
        failures: 1,
        failure: AiTierFailure(
          AiService.claude,
          AiRateLimited(
            'Too many requests for now.',
            DateTime(2026, 10, 1, 15, 45),
          ),
        ),
      ),
    );

    await tapKey(tester, CategoryWindow.askAiKey);

    final failure = tester.widget<Text>(find.byKey(CategoryAskPage.failureKey));
    expect(failure.data, contains('3:45'));
  });

  testWidgets('without AI keys, asking AI is locked, and opens where keys '
      'are added', (tester) async {
    await open(tester, using: _Categorizer(askable: false));

    expect(
      find.descendant(
        of: find.byKey(CategoryWindow.askAiKey),
        matching: find.byIcon(Icons.lock_outline),
      ),
      findsOneWidget,
    );
    await tapKey(tester, CategoryWindow.askAiKey);

    expect(find.byType(AiKeysForm), findsOneWidget);
  });

  testWidgets('an AI category explains itself, with nothing to ask', (
    tester,
  ) async {
    await open(tester, category: _suggestion);

    expect(find.textContaining('Races through games'), findsOneWidget);
    expect(find.byKey(CategoryWindow.askAiKey), findsNothing);
  });
}
