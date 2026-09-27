import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/export/domain/export_format.dart';
import 'package:youtube_takeout_manager/src/features/export/presentation/export_sheet.dart';

void main() {
  Future<Future<ExportFormat?>> openSheet(WidgetTester tester) async {
    late Future<ExportFormat?> picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => picked = showExportFormatSheet(context),
              child: const Text('Export'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('the sheet returns the picked format', (tester) async {
    var picked = await openSheet(tester);
    await tester.tap(find.text('Export as CSV'));
    await tester.pumpAndSettle();
    expect(await picked, ExportFormat.csv);

    picked = await openSheet(tester);
    await tester.tap(find.text('Export as JSON'));
    await tester.pumpAndSettle();
    expect(await picked, ExportFormat.json);
  });

  testWidgets('dismissing the sheet picks nothing', (tester) async {
    final picked = await openSheet(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(await picked, isNull);
  });
}
