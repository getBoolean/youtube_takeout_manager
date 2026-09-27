import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/history/data/history_html_parser.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

// Markup as Google's My Activity export writes it (from a real takeout).
const _watchCaption =
    '<b>Products:</b><br>&emsp;YouTube<br><b>Why is this here?</b><br>'
    '&emsp;This activity was saved to your Google Account because the '
    'following settings were on:&nbsp;YouTube watch history.&nbsp;You can '
    'control these settings &nbsp;<a href="https://myaccount.google.com/'
    'activitycontrols">here</a>.';

String _cell(String body, {String header = 'YouTube', String? caption}) =>
    '<div class="outer-cell mdl-cell mdl-cell--12-col mdl-shadow--2dp">'
    '<div class="mdl-grid"><div class="header-cell mdl-cell mdl-cell--12-col">'
    '<p class="mdl-typography--title">$header<br></p></div>\n'
    '<div class="content-cell mdl-cell mdl-cell--6-col '
    'mdl-typography--body-1">$body</div>\n'
    '<div class="content-cell mdl-cell mdl-cell--6-col mdl-typography--body-1 '
    'mdl-typography--text-right"></div>\n'
    '<div class="content-cell mdl-cell mdl-cell--12-col '
    'mdl-typography--caption">${caption ?? _watchCaption}</div>\n</div>\n</div>';

Uint8List _html(List<String> cells) => utf8.encode(
  '<html><head><title>My Activity History</title><style type="text/css">'
  'html{color:rgba(0,0,0,.87)}</style></head><body><div class="mdl-grid">'
  '${cells.join()}</div></body></html>',
);

String _watched(
  String videoId,
  String title, {
  String? channel = 'BenNumbers [Vtuber clips]',
  String date = 'Apr 12, 2026, 2:33:54\u202fAM CDT',
  String host = 'www.youtube.com',
}) =>
    'Watched\u00a0<a href="https://$host/watch?v=$videoId">$title</a><br>'
    '${channel == null ? '' : '<a href="https://www.youtube.com/channel/UCPhEmx4KRk22ahmi2Sb8UFg">$channel</a><br>'}'
    '$date<br>';

List<WatchEntry> _watches(List<String> cells, {Duration? localOffset}) =>
    parseWatchHistoryHtml(_html(cells), localOffset: localOffset).entries;

DateTime _timeOf(String date, {Duration? localOffset}) => _watches([
  _cell(_watched('v', 'T', date: date)),
], localOffset: localOffset).single.time;

void main() {
  group('watch history', () {
    test("reads a watched video's title, link, channel and time", () {
      final watch = _watches([
        _cell(_watched('16TBS4N2wDE', 'Peo Didn’t Notice Her Mic Was On')),
      ]).single;

      expect(watch.kind, WatchKind.video);
      expect(watch.title, 'Peo Didn’t Notice Her Mic Was On');
      expect(watch.videoId, '16TBS4N2wDE');
      expect(watch.url, 'https://www.youtube.com/watch?v=16TBS4N2wDE');
      expect(watch.channelTitle, 'BenNumbers [Vtuber clips]');
      expect(watch.channelId, 'UCPhEmx4KRk22ahmi2Sb8UFg');
      expect(watch.music, isFalse);
      // 2:33:54 AM CDT is 5 hours behind UTC.
      expect(watch.time, DateTime.utc(2026, 4, 12, 7, 33, 54));
    });

    test('reads every entry, in the order given', () {
      final watches = _watches([
        _cell(_watched('b', 'Second')),
        _cell(_watched('a', 'First')),
      ]);

      expect([for (final w in watches) w.title], ['Second', 'First']);
    });

    test('a removed video has no title or channel', () {
      const url = 'https://www.youtube.com/watch?v=XeSV7MYsnNU';
      final watch = _watches([
        _cell(
          'Watched\u00a0<a href="$url">$url</a><br>'
          'Apr 10, 2026, 2:53:00\u202fPM CDT<br>',
        ),
      ]).single;

      expect(watch.title, isNull);
      expect(watch.channelTitle, isNull);
      expect(watch.videoId, 'XeSV7MYsnNU');
    });

    test('YouTube Music watches are music', () {
      final watch = _watches([
        _cell(
          _watched('s9u7oQ7aaV0', 'ツバサ', host: 'music.youtube.com'),
          header: 'YouTube Music',
        ),
      ]).single;

      expect(watch.music, isTrue);
      expect(watch.videoId, 's9u7oQ7aaV0');
    });

    test('a Short is a video', () {
      final watch = _watches([
        _cell(
          'Watched\u00a0<a href="https://www.youtube.com/shorts/abc_-123">'
          'A short</a><br>Apr 12, 2026, 2:33:54\u202fAM CDT<br>',
        ),
      ]).single;

      expect(watch.kind, WatchKind.video);
      expect(watch.videoId, 'abc_-123');
    });

    test('posts and playables are told apart by their link', () {
      final watches = _watches([
        _cell(
          'Viewed\u00a0<a href="https://www.youtube.com/post/UgkxAbC">a post'
          '</a><br><a href="https://www.youtube.com/channel/UCremi">Remi</a>'
          '<br>Nov 11, 2025, 7:46:01\u202fPM CDT<br>',
        ),
        _cell(
          'Played\u00a0<a href="https://www.youtube.com/playables/UgkxQ-N">'
          'Hole.io</a><br>Mar 22, 2026, 12:31:45\u202fPM CDT<br>',
        ),
      ]);

      expect(
        [for (final w in watches) w.kind],
        [WatchKind.post, WatchKind.playable],
      );
      expect(watches.first.channelTitle, 'Remi');
      expect(watches.first.videoId, isNull);
    });

    test('entries without a link, and ads, are left out', () {
      final read = parseWatchHistoryHtml(
        _html([
          _cell(
            'Used Shorts creation tools<br>Dec 5, 2025, 9:22:22\u202fPM CDT<br>',
          ),
          _cell(
            'Viewed a post that is no longer available<br>'
            'Nov 11, 2025, 7:46:01\u202fPM CDT<br>',
          ),
          _cell(
            _watched('ad', 'An ad'),
            caption:
                '<b>Products:</b><br>&emsp;YouTube<br><b>Details:</b><br>'
                '&emsp;From Google Ads<br>',
          ),
          _cell(_watched('kept', 'Kept')),
        ]),
      );

      expect([for (final w in read.entries) w.title], ['Kept']);
      expect(read.skippedRows, 0);
    });

    test('HTML entities in titles and channels are decoded', () {
      final watch = _watches([
        _cell(
          _watched(
            'v',
            'Karl Jobst&#39;s &quot;Lawsuit&quot; &amp; &lt;more&gt; &#x1F600;',
            channel: 'Legal &amp; Co',
          ),
        ),
      ]).single;

      expect(watch.title, 'Karl Jobst\'s "Lawsuit" & <more> 😀');
      expect(watch.channelTitle, 'Legal & Co');
    });

    test('the zone label converts to UTC', () {
      expect(
        _timeOf('Jan 5, 2025, 11:00:00\u202fPM EST'),
        DateTime.utc(2025, 1, 6, 4),
      );
      expect(
        _timeOf('Jul 1, 2025, 12:15:30\u202fPM PDT'),
        DateTime.utc(2025, 7, 1, 19, 15, 30),
      );
      expect(
        _timeOf('Mar 3, 2025, 12:00:00\u202fAM UTC'),
        DateTime.utc(2025, 3, 3),
      );
      expect(
        _timeOf('Mar 3, 2025, 9:30:00\u202fAM GMT+09:00'),
        DateTime.utc(2025, 3, 3, 0, 30),
      );
      expect(
        _timeOf('Mar 3, 2025, 9:30:00\u202fAM GMT-3'),
        DateTime.utc(2025, 3, 3, 12, 30),
      );
    });

    test('day-first English dates are read too', () {
      expect(
        _timeOf('12 Apr 2026, 14:05:00 BST'),
        DateTime.utc(2026, 4, 12, 13, 5),
      );
      expect(
        _timeOf('3 Sept 2025, 09:00:00 CEST'),
        DateTime.utc(2025, 9, 3, 7),
      );
    });

    test("an ambiguous zone label takes the device's offset when it can", () {
      const date = 'Apr 12, 2026, 8:00:00\u202fPM CST';
      // China Standard Time is 8 hours ahead of UTC.
      expect(
        _timeOf(date, localOffset: const Duration(hours: 8)),
        DateTime.utc(2026, 4, 12, 12),
      );
      // Otherwise the US one, 6 hours behind.
      expect(
        _timeOf(date, localOffset: const Duration(hours: 1)),
        DateTime.utc(2026, 4, 13, 2),
      );
    });

    test('an unknown zone label reads as local time', () {
      expect(
        _timeOf('Apr 12, 2026, 8:00:00\u202fPM XYZT'),
        DateTime(2026, 4, 12, 20).toUtc(),
      );
    });

    test('an entry with an unreadable date is skipped and counted', () {
      final read = parseWatchHistoryHtml(
        _html([
          _cell(_watched('a', 'Readable')),
          _cell(_watched('b', 'Unreadable', date: '12 abr 2026, 2:33:54 CDT')),
        ]),
      );

      expect([for (final w in read.entries) w.title], ['Readable']);
      expect(read.skippedRows, 1);
      expect(read.unreadable, isFalse);
    });

    test('a file with no readable entries is reported unreadable', () {
      final read = parseWatchHistoryHtml(
        _html([
          _cell(_watched('a', 'A', date: '12 abr 2026, 2:33:54 CDT')),
          _cell(_watched('b', 'B', date: '11 abr 2026, 2:33:54 CDT')),
        ]),
      );

      expect(read.entries, isEmpty);
      expect(read.unreadable, isTrue);
    });

    test('an empty history is not unreadable', () {
      final read = parseWatchHistoryHtml(_html(const []));

      expect(read.entries, isEmpty);
      expect(read.unreadable, isFalse);
    });
  });

  group('search history', () {
    const searchCaption =
        '<b>Products:</b><br>&emsp;YouTube<br><b>Why is this here?</b><br>'
        '&emsp;YouTube search history.';

    test("a search's query and time are read from its link", () {
      final search = parseSearchHistoryHtml(
        _html([
          _cell(
            'Searched for\u00a0<a href="https://www.youtube.com/results?'
            'search_query=mkworld+records">mkworld records</a><br>'
            'Apr 11, 2026, 9:59:48\u202fPM CDT<br>',
            caption: searchCaption,
          ),
        ]),
      ).entries.single;

      expect(search.query, 'mkworld records');
      expect(search.time, DateTime.utc(2026, 4, 12, 2, 59, 48));
      expect(search.music, isFalse);
    });

    test("the query doesn't depend on the export's language", () {
      final search = parseSearchHistoryHtml(
        _html([
          _cell(
            'Buscaste\u00a0<a href="https://www.youtube.com/results?'
            'search_query=caf%C3%A9+%26+t%C3%A9">café &amp; té</a><br>'
            'Apr 11, 2026, 9:59:48\u202fPM CDT<br>',
            caption: searchCaption,
          ),
        ]),
      ).entries.single;

      expect(search.query, 'café & té');
    });

    test('YouTube Music searches are music', () {
      final search = parseSearchHistoryHtml(
        _html([
          _cell(
            'Searched for\u00a0<a href="https://music.youtube.com/search?'
            'q=luminary">luminary</a><br>Apr 11, 2026, 9:59:48\u202fPM CDT<br>',
            header: 'YouTube Music',
            caption: searchCaption,
          ),
        ]),
      ).entries.single;

      expect(search.query, 'luminary');
      expect(search.music, isTrue);
    });
  });
}
