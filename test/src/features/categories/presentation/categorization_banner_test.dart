import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorization_progress.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/pending_ai_work.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/run_estimate.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/categorization_banner.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/tag_pages.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

class _Categorizer extends ChannelCategorizer {
  var runs = 0;
  var stops = 0;

  @override
  void build() {}

  @override
  void run() => runs++;

  @override
  void stop() => stops++;
}

class _Progress extends CategorizationProgress {
  _Progress(this.progress);

  final RunProgress progress;

  @override
  RunProgress build() => progress;
}

class _Pending extends PendingAiWork {
  _Pending(this.summary);

  final AiWorkSummary? summary;

  @override
  AiWorkSummary? build() => summary;
}

class _Spent extends ClaudeUsage {
  @override
  ({int input, int output}) build() => (input: 2000000, output: 100000);
}

const _idle = (
  running: false,
  ai: false,
  done: 0,
  total: 0,
  redo: false,
  stopping: false,
  interrupted: false,
);

const _waiting = AiWorkSummary(
  categorize: 300,
  redo: 0,
  tags: 12,
  checks: 0,
  uncategorized: 0,
  evidenceChars: [1000],
);

Future<_Categorizer> _pump(
  WidgetTester tester, {
  RunProgress progress = _idle,
  AiWorkSummary? summary,
  AiKeys keys = const AiKeys(anthropic: 'sk-ant-1'),
  List<Override> overrides = const [],
}) async {
  final categorizer = _Categorizer();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        channelCategorizerProvider.overrideWith(() => categorizer),
        categorizationProgressProvider.overrideWith(() => _Progress(progress)),
        pendingAiWorkProvider.overrideWith(() => _Pending(summary)),
        aiKeysProvider.overrideWith((ref) async => keys),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: CategorizationBanner()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return categorizer;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets("during the user's run, shows how far along it is and what "
      'Claude has cost, and Stop stops it', (tester) async {
    final categorizer = await _pump(
      tester,
      progress: (
        running: true,
        ai: true,
        done: 40,
        total: 120,
        redo: false,
        stopping: false,
        interrupted: false,
      ),
      overrides: [claudeUsageProvider.overrideWith(_Spent.new)],
    );

    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(40 / 120, 0.001),
    );
    expect(find.textContaining(r'$'), findsOneWidget);

    await tester.tap(find.byKey(CategorizationBanner.stopKey));
    expect(categorizer.stops, 1);
  });

  testWidgets('while stopping, offers no Stop', (tester) async {
    await _pump(
      tester,
      progress: (
        running: true,
        ai: true,
        done: 40,
        total: 120,
        redo: false,
        stopping: true,
        interrupted: false,
      ),
    );

    expect(
      tester
          .widget<OutlinedButton>(find.byKey(CategorizationBanner.stopKey))
          .onPressed,
      isNull,
    );
  });

  testWidgets("YouTube's run alone shows nothing", (tester) async {
    await _pump(
      tester,
      progress: (
        running: true,
        ai: false,
        done: 4,
        total: 12,
        redo: false,
        stopping: false,
        interrupted: false,
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('after the user stopped a run, Continue goes on with it', (
    tester,
  ) async {
    final categorizer = await _pump(
      tester,
      progress: (
        running: false,
        ai: true,
        done: 40,
        total: 120,
        redo: false,
        stopping: false,
        interrupted: true,
      ),
      summary: _waiting,
    );

    await tester.tap(find.byKey(CategorizationBanner.continueKey));

    expect(categorizer.runs, 1);
  });

  testWidgets('with a key and channels waiting for AI, says how many, and '
      'Categorize opens the window', (tester) async {
    await _pump(tester, summary: _waiting);

    expect(find.textContaining('312'), findsOneWidget);

    await tester.tap(find.byKey(CategorizationBanner.categorizeKey));
    await tester.pumpAndSettle();
    expect(find.byKey(TagsPage.defineKey), findsOneWidget);
  });

  testWidgets('without a key, says nothing of channels waiting for AI', (
    tester,
  ) async {
    await _pump(tester, summary: _waiting, keys: AiKeys.none);

    expect(find.byKey(CategorizationBanner.categorizeKey), findsNothing);
  });
}
