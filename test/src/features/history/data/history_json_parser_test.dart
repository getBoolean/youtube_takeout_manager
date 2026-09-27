import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/data/history_html_parser.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_json_parser.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

const _channelUrl = 'https://www.youtube.com/channel/UCPhEmx4KRk22ahmi2Sb8UFg';

/// A watch history entry as Google's JSON export writes it.
Map<String, Object?> _watched(
  String videoId,
  String title, {
  String verb = 'Watched ',
  String suffix = '',
  String? channel = 'BenNumbers',
  String time = '2026-04-12T07:33:54.123Z',
  String header = 'YouTube',
  String host = 'www.youtube.com',
  bool ad = false,
}) => {
  'header': header,
  'title': '$verb$title$suffix',
  'titleUrl': 'https://$host/watch?v=$videoId',
  if (channel != null)
    'subtitles': [
      {'name': channel, 'url': _channelUrl},
    ],
  'time': time,
  'products': ['YouTube'],
  if (ad)
    'details': [
      {'name': 'From Google Ads'},
    ],
  'activityControls': ['YouTube watch history'],
};

Uint8List _json(List<Map<String, Object?>> entries) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(entries));

List<WatchEntry> _watches(List<Map<String, Object?>> entries) =>
    parseWatchHistoryJson(_json(entries)).entries;

void main() {
  group('watch history', () {
    test("reads a watched video's title, link, channel and time", () {
      final watch = _watches([
        _watched('16TBS4N2wDE', 'Peo Didn’t Notice Her Mic Was On'),
      ]).single;

      expect(watch.kind, WatchKind.video);
      expect(watch.title, 'Peo Didn’t Notice Her Mic Was On');
      expect(watch.videoId, '16TBS4N2wDE');
      expect(watch.channelTitle, 'BenNumbers');
      expect(watch.channelId, 'UCPhEmx4KRk22ahmi2Sb8UFg');
      expect(watch.time, DateTime.utc(2026, 4, 12, 7, 33, 54, 123));
      expect(watch.music, isFalse);
    });

    test('JSON and HTML of the same history read the same entries', () {
      final json = parseWatchHistoryJson(
        _json([
          _watched('a1', 'A & B', time: '2026-04-12T07:33:54.123Z'),
          _watched(
            'm1',
            'Song',
            header: 'YouTube Music',
            host: 'music.youtube.com',
            time: '2026-04-11T01:00:00Z',
          ),
        ]),
      ).entries;
      final html = parseWatchHistoryHtml(
        utf8.encode(
          '<html><body>'
          '<div class="outer-cell"><p class="mdl-typography--title">YouTube<br>'
          '</p><div class="content-cell mdl-typography--body-1">'
          'Watched\u00a0<a href="https://www.youtube.com/watch?v=a1">A &amp; B'
          '</a><br><a href="$_channelUrl">BenNumbers</a><br>'
          'Apr 12, 2026, 2:33:54\u202fAM CDT<br></div></div>'
          '<div class="outer-cell"><p class="mdl-typography--title">'
          'YouTube Music<br></p><div class="content-cell '
          'mdl-typography--body-1">Watched\u00a0<a href="https://'
          'music.youtube.com/watch?v=m1">Song</a><br><a href="$_channelUrl">'
          'BenNumbers</a><br>Apr 10, 2026, 8:00:00\u202fPM CDT<br></div></div>'
          '</body></html>',
        ),
      ).entries;

      String describe(WatchEntry w) =>
          '${w.kind} ${w.music} ${w.title} ${w.url} ${w.channelTitle} '
          '${w.channelUrl} ${w.time.millisecondsSinceEpoch ~/ 1000}';
      expect(json.map(describe), html.map(describe));
    });

    test('a removed video has no title', () {
      const url = 'https://www.youtube.com/watch?v=XeSV7MYsnNU';
      final watch = _watches([
        {
          'header': 'YouTube',
          'title': 'Watched $url',
          'titleUrl': url,
          'time': '2026-04-10T19:53:00Z',
        },
      ]).single;

      expect(watch.title, isNull);
      expect(watch.channelTitle, isNull);
      expect(watch.videoId, 'XeSV7MYsnNU');
    });

    test("a localized verb is stripped from titles", () {
      final watches = _watches([
        _watched('a', 'Mario Kart', verb: 'Has visto '),
        _watched('b', 'Minecraft', verb: 'Has visto '),
        _watched('c', 'Música nueva', verb: 'Has visto '),
      ]);

      expect(
        [for (final w in watches) w.title],
        ['Mario Kart', 'Minecraft', 'Música nueva'],
      );
    });

    test('a localized verb after the title is stripped too', () {
      final watches = _watches([
        _watched('a', 'マリオカート', verb: '', suffix: ' を視聴しました'),
        _watched('b', 'ホロライブ', verb: '', suffix: ' を視聴しました'),
      ]);

      expect([for (final w in watches) w.title], ['マリオカート', 'ホロライブ']);
    });

    test('ads and entries without a link are left out', () {
      final watches = _watches([
        _watched('ad', 'An ad', ad: true),
        {
          'header': 'YouTube',
          'title': 'Watched a video that has been removed',
          'time': '2026-04-10T19:53:00Z',
        },
        _watched('kept', 'Kept'),
      ]);

      expect([for (final w in watches) w.title], ['Kept']);
    });

    test('posts and playables are told apart by their link', () {
      final watches = _watches([
        {
          'header': 'YouTube',
          'title': 'Viewed a post',
          'titleUrl': 'https://www.youtube.com/post/UgkxAbC',
          'time': '2025-11-11T19:46:01Z',
        },
        {
          'header': 'YouTube',
          'title': 'Played Hole.io',
          'titleUrl': 'https://www.youtube.com/playables/UgkxQ-N',
          'time': '2026-03-22T17:31:45Z',
        },
      ]);

      expect(
        [for (final w in watches) w.kind],
        [WatchKind.post, WatchKind.playable],
      );
      expect(watches.last.title, 'Hole.io');
    });

    test('an entry with an unreadable time is skipped and counted', () {
      final read = parseWatchHistoryJson(
        _json([_watched('a', 'A'), _watched('b', 'B', time: 'yesterday')]),
      );

      expect([for (final w in read.entries) w.title], ['A']);
      expect(read.skippedRows, 1);
      expect(read.unreadable, isFalse);
    });

    test('a file with no readable entries is reported unreadable', () {
      final read = parseWatchHistoryJson(
        _json([_watched('a', 'A', time: 'yesterday')]),
      );

      expect(read.entries, isEmpty);
      expect(read.unreadable, isTrue);
    });

    test('an empty history is not unreadable', () {
      final read = parseWatchHistoryJson(utf8.encode('[]'));

      expect(read.entries, isEmpty);
      expect(read.unreadable, isFalse);
    });

    test('braces and quotes inside strings are read as text', () {
      final watch = _watches([
        _watched('a', r'He said "{ok}" \ [really]'),
      ]).single;

      expect(watch.title, r'He said "{ok}" \ [really]');
    });
  });

  group('search history', () {
    test("a search's query comes from its link", () {
      final search = parseSearchHistoryJson(
        _json([
          {
            'header': 'YouTube',
            'title': 'Buscaste café & té',
            'titleUrl':
                'https://www.youtube.com/results?search_query=caf%C3%A9+%26+t%C3%A9',
            'time': '2026-04-12T02:59:48.500Z',
          },
          {
            'header': 'YouTube Music',
            'title': 'Searched for luminary',
            'titleUrl': 'https://music.youtube.com/search?q=luminary',
            'time': '2026-04-11T02:59:48Z',
          },
        ]),
      ).entries;

      expect([for (final s in search) s.query], ['café & té', 'luminary']);
      expect([for (final s in search) s.music], [false, true]);
      expect(search.first.time, DateTime.utc(2026, 4, 12, 2, 59, 48, 500));
    });
  });
}
