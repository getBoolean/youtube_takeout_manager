// ignore_for_file: avoid_print

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('find skipped rows', () {
    final dir = Directory(
      'takeout_extracted/Takeout/YouTube and YouTube Music/comments',
    );
    final csv = Csv(autoDetect: false);
    var totalSkipped = 0;

    for (final file in dir.listSync().whereType<File>()) {
      final content = file.readAsStringSync();
      final rows = csv.decode(content);
      if (rows.isEmpty) continue;

      final minCols = rows.first.length;
      final dataRows = rows.skip(1).toList();

      for (var i = 0; i < dataRows.length; i++) {
        if (dataRows[i].length < minCols) {
          totalSkipped++;
          print('SKIPPED in ${file.uri.pathSegments.last}');
          print('  Row ${i + 2}: ${dataRows[i].length} cols (need $minCols)');
          print('  Content: ${dataRows[i]}');
          print('');
        }
      }
    }
    print('Total skipped: $totalSkipped');
  });
}
