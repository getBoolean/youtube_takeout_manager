import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';

void main() {
  test('counts regular nouns by adding an s', () {
    expect(formatCount(1, 'comment'), '1 comment');
    expect(formatCount(1234, 'comment'), '1,234 comments');
  });

  test('counts irregular nouns with their plural', () {
    expect(formatCount(1, 'search', plural: 'searches'), '1 search');
    expect(formatCount(8296, 'search', plural: 'searches'), '8,296 searches');
  });
}
