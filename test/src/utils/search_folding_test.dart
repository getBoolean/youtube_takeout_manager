import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/utils/search_folding.dart';

void main() {
  group('foldForSearch', () {
    test('lowercases and drops the emoji presentation selector', () {
      expect(foldForSearch('Love ❤️ It'), 'love ❤ it');
    });

    test('keeps skin tones and ZWJ sequences', () {
      const thumbsUpMedium = '\u{1F44D}\u{1F3FD}';
      const technologist = '\u{1F9D1}‍\u{1F4BB}';
      expect(foldForSearch(thumbsUpMedium), thumbsUpMedium);
      expect(foldForSearch(technologist), technologist);
    });

    test('ignores accents, written as one character or as two', () {
      expect(foldForSearch('Café'), foldForSearch('cafe'));
      expect(foldForSearch('Café'), foldForSearch('cafe'));
      expect(foldForSearch('Ñandú Çà Øre'), foldForSearch('nandu ca ore'));
    });

    test('matches letters that stand for two', () {
      expect(foldForSearch('Straße'), foldForSearch('strasse'));
      expect(foldForSearch('Æsir'), foldForSearch('aesir'));
    });

    test('matches a dotted capital I', () {
      expect(foldForSearch('İstanbul'), foldForSearch('istanbul'));
    });
  });
}
