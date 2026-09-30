import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/adaptive_segmented_button.dart';

enum _Pick { all, some, none }

Future<List<_Pick>> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final picked = <_Pick>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: AdaptiveSegmentedButton<_Pick>(
              segments: const [
                AdaptiveSegment(
                  value: _Pick.all,
                  label: 'Everything',
                  icon: Icons.done_all,
                ),
                AdaptiveSegment(value: _Pick.some, label: 'Only some'),
                AdaptiveSegment(value: _Pick.none, label: 'None of them'),
              ],
              selected: _Pick.all,
              onChanged: picked.add,
            ),
          ),
        ),
      ),
    ),
  );
  return picked;
}

Axis _direction(WidgetTester tester) => tester
    .widget<SegmentedButton<_Pick>>(find.byType(SegmentedButton<_Pick>))
    .direction;

void main() {
  testWidgets('sits in a row when every label fits', (tester) async {
    await _pump(tester, 1000);

    expect(_direction(tester), Axis.horizontal);
  });

  testWidgets('stacks its choices rather than squeezing their labels', (
    tester,
  ) async {
    await _pump(tester, 200);

    expect(_direction(tester), Axis.vertical);
  });

  testWidgets('picking a choice says which', (tester) async {
    final picked = await _pump(tester, 1000);

    await tester.tap(find.text('Only some'));
    await tester.pump();

    expect(picked, [_Pick.some]);
  });
}
