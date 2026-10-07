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
  test('the question before clearing names how many channels go back, and '
      'no price: nothing is asked of AI until the next run', () {
    final question = clearAiQuestion(channels: 1234);

    expect(question, contains('1,234'));
    expect(question, isNot(contains(r'$')));
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
