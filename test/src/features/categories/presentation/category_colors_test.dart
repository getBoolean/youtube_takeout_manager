import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/youtube_taxonomy.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_colors.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  final parents = youtubeTaxonomy.parents.toList();

  test('each category has a colour of its own, in light and dark', () {
    for (final brightness in Brightness.values) {
      final colours = {
        for (final parent in parents) categoryColor(parent, brightness),
      };
      expect(colours, hasLength(parents.length), reason: '$brightness');
      expect(
        colours,
        isNot(contains(categoryColor(null, brightness))),
        reason: 'Uncategorized is apart',
      );
    }
  });

  test('text stays readable on every tinted pill', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      for (final parent in [...parents, null]) {
        expect(
          _contrast(scheme.onSurface, categoryTint(parent, scheme)),
          greaterThanOrEqualTo(4.5),
          reason: '$parent, ${scheme.brightness}',
        );
      }
    }
  });

  testWidgets("the AI mark tells a screen reader AI made it", (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiMark())));

    expect(find.bySemanticsLabel(RegExp('AI')), findsOneWidget);
  });
}
