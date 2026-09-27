import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  final history = TakeoutHistory(
    watches: [
      WatchEntry(
        time: DateTime.utc(2026, 4, 12, 7, 33, 54, 123),
        kind: WatchKind.video,
        title: 'Quotes "and", commas\nand lines',
        url: 'https://www.youtube.com/watch?v=abc',
        channelTitle: 'Shortcat',
        channelUrl: 'https://www.youtube.com/channel/UCsc',
      ),
      WatchEntry(
        time: DateTime.utc(2026, 4, 11),
        kind: WatchKind.video,
        music: true,
        url: 'https://music.youtube.com/watch?v=gone',
        removedAt: DateTime.utc(2026, 5),
      ),
      WatchEntry(
        time: DateTime.utc(2026, 4, 10),
        kind: WatchKind.post,
        title: 'A post',
        url: 'https://www.youtube.com/post/Ugkx',
      ),
    ],
    searches: [
      SearchEntry(time: DateTime.utc(2026, 4, 12), query: 'café, "té"'),
      SearchEntry(time: DateTime.utc(2026, 4, 11), query: '007; a\tb'),
      SearchEntry(
        time: DateTime.utc(2026, 4, 1),
        music: true,
        query: 'luminary',
        removedAt: DateTime.utc(2026, 5),
      ),
    ],
    watchesSnapshot: DateTime.utc(2026, 5),
    searchesSnapshot: DateTime.utc(2026, 4, 20),
  );

  test('saved history reads back as the same entries, removal marks too', () {
    final read = parseSavedHistory(encodeHistoryCsvs(history));

    expect(read.watches, history.watches);
    expect(read.searches, history.searches);
    expect(read.watchesSnapshot, DateTime.utc(2026, 5));
    expect(read.searchesSnapshot, DateTime.utc(2026, 4, 20));
  });

  test('no saved history reads as none', () {
    final read = parseSavedHistory(const {});

    expect(read.isEmpty, isTrue);
    expect(read.watchesSnapshot, isNull);
  });

  test('saved history with its columns in another order still reads', () {
    final read = parseSavedHistory({
      '_history/watches.csv': _bytes(
        'URL,Removed At,Time,Title,Kind,Music,Channel Title,Channel URL\r\n'
        'https://www.youtube.com/watch?v=abc,,2026-04-12T07:33:54.000Z,'
        'A video,video,false,Shortcat,https://www.youtube.com/channel/UCsc\r\n',
      ),
    });

    final watch = read.watches.single;
    expect(watch.title, 'A video');
    expect(watch.videoId, 'abc');
    expect(watch.channelTitle, 'Shortcat');
    expect(watch.time, DateTime.utc(2026, 4, 12, 7, 33, 54));
  });
}
