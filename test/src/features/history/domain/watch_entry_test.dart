import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

WatchEntry _entry(String url, {WatchKind kind = WatchKind.video}) =>
    WatchEntry(time: DateTime.utc(2026, 4, 12), kind: kind, url: url);

void main() {
  test('a video watched through its Shorts link is a Short', () {
    expect(_entry('https://www.youtube.com/shorts/abc_-123').isShort, isTrue);
  });

  test('a video watched through its usual link is not a Short', () {
    expect(_entry('https://www.youtube.com/watch?v=abc').isShort, isFalse);
  });

  test('a post is never a Short', () {
    expect(
      _entry(
        'https://www.youtube.com/post/shorts/x',
        kind: WatchKind.post,
      ).isShort,
      isFalse,
    );
  });
}
