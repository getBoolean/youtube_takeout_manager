import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_results_clearer.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/clear_ai_results_section.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

class _Clearer extends AiResultsClearer {
  var cleared = 0;

  @override
  Future<void> clear() async => cleared++;
}

void main() {
  group('the question before clearing', () {
    test('with Claude and its usual model, says how many channels and '
        'roughly what it costs', () {
      final question = clearAiQuestion(
        channels: 1234,
        keys: const AiKeys(anthropic: 'sk-ant-1'),
        model: defaultAnthropicModel,
      );

      expect(question, contains('1,234'));
      expect(question, contains(r'$5'));
    });

    test('a few channels cost less than a dollar', () {
      expect(
        clearAiQuestion(
          channels: 12,
          keys: const AiKeys(anthropic: 'sk-ant-1'),
          model: defaultAnthropicModel,
        ),
        contains(r'$1'),
      );
    });

    test('with another model, names no price', () {
      final question = clearAiQuestion(
        channels: 1234,
        keys: const AiKeys(anthropic: 'sk-ant-1'),
        model: 'claude-opus-5-5',
      );

      expect(question, contains('1,234'));
      expect(question, isNot(contains(r'$')));
    });

    test('with Jev alone, or no key, names no price', () {
      for (final keys in [const AiKeys(typesafe: 'jv_live_1'), AiKeys.none]) {
        expect(
          clearAiQuestion(
            channels: 1234,
            keys: keys,
            model: defaultAnthropicModel,
          ),
          isNot(contains(r'$')),
        );
      }
    });
  });

  testWidgets('clearing asks first, in place, then clears', (tester) async {
    final clearer = _Clearer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiResultsClearerProvider.overrideWith(() => clearer),
          aiKeysProvider.overrideWith((ref) async => AiKeys.none),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ClearAiResultsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ClearAiResultsSection.actionKey));
    await tester.pumpAndSettle();
    expect(clearer.cleared, 0);
    await tester.tap(find.byKey(ClearAiResultsSection.confirmKey));
    await tester.pumpAndSettle();

    expect(clearer.cleared, 1);
  });
}
