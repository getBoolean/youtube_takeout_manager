import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/domain/my_activity_results.dart';

void main() {
  test('reads what was deleted and why the rest failed', () {
    final parsed = parseMyActivityResults(
      '{"succeeded":["c1","l1"],'
      '"failed":[{"id":"c2","error":"Not found"},{"id":"l2","error":"403"}]}',
    );

    expect(parsed, isA<MyActivityResults>());
    final results = parsed as MyActivityResults;
    expect(results.deleted, {'c1', 'l1'});
    expect(results.failed, [
      (id: 'c2', error: 'Not found'),
      (id: 'l2', error: '403'),
    ]);
    expect(results.errorsById, {'c2': 'Not found', 'l2': '403'});
  });

  test('reads a run where nothing failed', () {
    final parsed = parseMyActivityResults('{"succeeded":[],"failed":[]}');

    expect(parsed, isA<MyActivityResults>());
    expect((parsed as MyActivityResults).deleted, isEmpty);
    expect(parsed.failed, isEmpty);
  });

  test('text that isn’t JSON is malformed, saying why', () {
    final parsed = parseMyActivityResults('{"succeeded":');

    expect(parsed, isA<MalformedMyActivityResults>());
    expect((parsed as MalformedMyActivityResults).error, isNotEmpty);
  });

  for (final (name, text) in [
    ('a list', '["c1"]'),
    ('no failures', '{"succeeded":["c1"]}'),
    ('an ID that isn’t text', '{"succeeded":[1],"failed":[]}'),
    ('a failure without an error', '{"succeeded":[],"failed":[{"id":"c"}]}'),
  ]) {
    test('JSON with $name is malformed', () {
      expect(parseMyActivityResults(text), isA<MalformedMyActivityResults>());
    });
  }
}
