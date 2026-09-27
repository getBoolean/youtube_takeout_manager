import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/utils/web_url.dart';

void main() {
  test('isWebUrl accepts only http and https URLs', () {
    expect(isWebUrl('https://yt3.ggpht.com/abc'), isTrue);
    expect(isWebUrl('http://example.com'), isTrue);
    expect(isWebUrl('Failed to get emoji URL'), isFalse);
    expect(isWebUrl('file:///c:/a.png'), isFalse);
    expect(isWebUrl(''), isFalse);
  });
}
