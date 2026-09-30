import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

const _content = ValueKey('modal-content');

/// Opens a modal in the app's theme in a window [width] wide, and returns
/// where its content landed.
Future<Rect> _openModal(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => WoltModalSheet.show<void>(
              context: context,
              pageListBuilder: (_) => [
                WoltModalSheetPage(
                  hasTopBarLayer: false,
                  child: const SizedBox(key: _content, height: 100),
                ),
              ],
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return tester.getRect(find.byKey(_content));
}

void main() {
  testWidgets('on a phone, modals rise from the bottom as sheets', (
    tester,
  ) async {
    final content = await _openModal(tester, 400);

    expect(content.bottom, closeTo(900, 40));
  });

  testWidgets('on a tablet, modals are dialogs in the middle', (tester) async {
    final content = await _openModal(tester, 700);

    expect(content.center.dy, closeTo(450, 40));
  });

  testWidgets('on a desktop, modals are dialogs in the middle', (tester) async {
    final content = await _openModal(tester, 1300);

    expect(content.center.dy, closeTo(450, 40));
  });

  testWidgets(
    'just under the width the app switches layouts at, still a sheet',
    (tester) async {
      // Wider than the package's own switch, narrower than the app's.
      final content = await _openModal(tester, 560);

      expect(content.bottom, closeTo(900, 40));
    },
  );
}
