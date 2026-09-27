import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/csv_header.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';

void main() {
  final header = CsvHeader([' Channel ID', 'Title ', 'TIME'], 'watch history');

  test('finds columns whatever their case or spacing', () {
    expect(header.optional('channel id'), 0);
    expect(header.optional('title'), 1);
    expect(header.required('Time'), 2);
  });

  test('tries other names for a column', () {
    expect(header.optional('created at', ['time']), 2);
  });

  test('a column that is not there is null when optional', () {
    expect(header.optional('url'), isNull);
  });

  test('a missing required column names it and the file', () {
    expect(
      () => header.required('URL'),
      throwsA(
        isA<TakeoutImportException>()
            .having((e) => e.message, 'message', contains('"URL"'))
            .having((e) => e.message, 'message', contains('watch history')),
      ),
    );
  });
}
