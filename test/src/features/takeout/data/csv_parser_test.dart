import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/data/csv_parser.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';

Uint8List _toBytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  late CsvParser parser;

  setUp(() {
    parser = CsvParser();
  });

  group('parseCommentsCsv', () {
    test('parses 9-column format (with Post ID)', () {
      const header =
          'Comment ID,Channel ID,Comment Create Timestamp,Price,'
          'Parent Comment ID,Post ID,Video ID,Comment Text,'
          'Top-Level Comment ID';
      final csv =
          '$header\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,parent1,post1,vid1,'
          '"{"text":"hello"}",top1\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      final c = result.items.first;
      expect(c.commentId, 'cid1');
      expect(c.postId, 'post1');
      expect(c.videoId, 'vid1');
      expect(c.displayText, 'hello');
      expect(c.parentCommentId, 'parent1');
      expect(c.topLevelCommentId, 'top1');
    });

    test('parses 8-column format (no Post ID)', () {
      const header =
          'Comment ID,Channel ID,Comment Create Timestamp,Price,'
          'Parent Comment ID,Video ID,Comment Text,Top-Level Comment ID';
      final csv =
          '$header\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,vid1,'
          '"{"text":"hello"}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      final c = result.items.first;
      expect(c.commentId, 'cid1');
      expect(c.postId, isNull);
      expect(c.videoId, 'vid1');
      expect(c.displayText, 'hello');
    });

    test('parses comment with literal newline in quoted text field', () {
      const header =
          'Comment ID,Channel ID,Comment Create Timestamp,Price,'
          'Parent Comment ID,Video ID,Comment Text,Top-Level Comment ID';
      final csv =
          '$header\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,vid1,'
          '"{"text":"line1\nline2"}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
    });

    test('parses comment with commas in quoted text field', () {
      const header =
          'Comment ID,Channel ID,Comment Create Timestamp,Price,'
          'Parent Comment ID,Video ID,Comment Text,Top-Level Comment ID';
      final csv =
          '$header\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,vid1,'
          '"{"text":"hello, world, test"}",\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.displayText, 'hello, world, test');
    });

    test('parses multiple comments without skipping any', () {
      const header =
          'Comment ID,Channel ID,Comment Create Timestamp,Price,'
          'Parent Comment ID,Video ID,Comment Text,Top-Level Comment ID';
      final csv =
          '$header\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,,vid1,'
          '"{"text":"hello"}",cid1\r\n'
          'cid2,ch1,2024-01-02T00:00:00.000Z,0.0,,vid2,'
          '"{"text":"world"}",cid2\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items, hasLength(2));
      expect(result.skippedRowCount, 0);
    });

    test('returns empty result for empty input', () {
      final result = parser.parseCommentsCsv(_toBytes(''));
      expect(result.items, isEmpty);
      expect(result.parsedRowCount, 0);
    });
  });

  group('parseLiveChatsCsv', () {
    test('parses 6-column format (no Currency, no Parent)', () {
      const header =
          'Live Chat ID,Channel ID,Live Chat Create Timestamp,'
          'Price,Video ID,Live Chat Text';
      final csv =
          '$header\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,0.0,vid1,'
          '"{"text":"hello"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      final lc = result.items.first;
      expect(lc.liveChatId, 'lc1');
      expect(lc.currencyCode, isNull);
      expect(lc.videoId, 'vid1');
    });

    test('parses 7-column format with Currency code', () {
      const header =
          'Live Chat ID,Channel ID,Live Chat Create Timestamp,'
          'Price,Currency code,Video ID,Live Chat Text';
      final csv =
          '$header\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,10.0,USD,vid1,'
          '"{"text":"superchat!"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.price, 10.0);
      expect(result.items.first.currencyCode, 'USD');
    });

    test('parses 7-column format with Parent Live Chat ID', () {
      const header =
          'Live Chat ID,Channel ID,Live Chat Create Timestamp,'
          'Price,Parent Live Chat ID,Video ID,Live Chat Text';
      final csv =
          '$header\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,0.0,,vid1,'
          '"{"text":"reply"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.currencyCode, isNull);
    });

    test('parses 8-column format with Currency and Parent', () {
      const header =
          'Live Chat ID,Channel ID,Live Chat Create Timestamp,'
          'Price,Currency code,Parent Live Chat ID,Video ID,Live Chat Text';
      final csv =
          '$header\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,5.0,EUR,,vid1,'
          '"{"text":"euro superchat"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
      expect(result.items.first.price, 5.0);
      expect(result.items.first.currencyCode, 'EUR');
    });

    test('parses live chat with literal newline in quoted text field', () {
      const header =
          'Live Chat ID,Channel ID,Live Chat Create Timestamp,'
          'Price,Video ID,Live Chat Text';
      final csv =
          '$header\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,0.0,vid1,'
          '"{"text":"line1\nline2"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(1));
      expect(result.skippedRowCount, 0);
    });

    test('parses multiple live chats without skipping any', () {
      const header =
          'Live Chat ID,Channel ID,Live Chat Create Timestamp,'
          'Price,Video ID,Live Chat Text';
      final csv =
          '$header\r\n'
          'lc1,ch1,2024-01-01T00:00:00.000Z,0.0,vid1,'
          '"{"text":"hello"}"\r\n'
          'lc2,ch1,2024-01-02T00:00:00.000Z,0.0,vid2,'
          '"{"text":"world"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items, hasLength(2));
      expect(result.skippedRowCount, 0);
    });

    test('names a missing column instead of crashing', () {
      const csv =
          'Live Chat ID,Channel ID,Price,Video ID,Live Chat Text\r\n'
          'lc1,ch1,0.0,vid1,"{"text":"hello"}"\r\n';

      expect(
        () => parser.parseLiveChatsCsv(_toBytes(csv)),
        throwsA(
          isA<TakeoutImportException>().having(
            (e) => e.message,
            'message',
            contains('Live Chat Create Timestamp'),
          ),
        ),
      );
    });

    test('skips a row with an unreadable timestamp and keeps the rest', () {
      const header =
          'Live Chat ID,Channel ID,Live Chat Create Timestamp,'
          'Price,Video ID,Live Chat Text';
      final csv =
          '$header\r\n'
          'lc1,ch1,not a date,0.0,vid1,"{"text":"hello"}"\r\n'
          'lc2,ch1,2024-01-02T00:00:00.000Z,0.0,vid2,"{"text":"world"}"\r\n';

      final result = parser.parseLiveChatsCsv(_toBytes(csv));
      expect(result.items.map((c) => c.liveChatId), ['lc2']);
      expect(result.skippedRowCount, 1);
    });
  });

  group('unexpected comments CSVs', () {
    test('names a missing column instead of crashing', () {
      const csv =
          'Comment ID,Channel ID,Comment Create Timestamp,Price,Video ID\r\n'
          'cid1,ch1,2024-01-01T00:00:00.000Z,0.0,vid1\r\n';

      expect(
        () => parser.parseCommentsCsv(_toBytes(csv)),
        throwsA(
          isA<TakeoutImportException>().having(
            (e) => e.message,
            'message',
            contains('Comment Text'),
          ),
        ),
      );
    });

    test('skips a row with an unreadable timestamp and keeps the rest', () {
      const header =
          'Comment ID,Channel ID,Comment Create Timestamp,Price,'
          'Video ID,Comment Text';
      final csv =
          '$header\r\n'
          'cid1,ch1,,0.0,vid1,"{"text":"hello"}"\r\n'
          'cid2,ch1,2024-01-02T00:00:00.000Z,0.0,vid2,"{"text":"world"}"\r\n';

      final result = parser.parseCommentsCsv(_toBytes(csv));
      expect(result.items.map((c) => c.commentId), ['cid2']);
      expect(result.skippedRowCount, 1);
    });
  });

  group('parseSubscriptionsCsv', () {
    test("reads Google's subscriptions.csv", () {
      const csv =
          'Channel Id,Channel Url,Channel Title\r\n'
          'UC1,http://www.youtube.com/channel/UC1,"First, too"\r\n'
          'UC2,http://www.youtube.com/channel/UC2,Second\r\n';

      final subs = parser.parseSubscriptionsCsv(_toBytes(csv));

      expect(subs.map((s) => (s.channelId, s.channelUrl, s.channelTitle)), [
        ('UC1', 'http://www.youtube.com/channel/UC1', 'First, too'),
        ('UC2', 'http://www.youtube.com/channel/UC2', 'Second'),
      ]);
    });

    test('reads the copy the app saved', () {
      const sub = Subscription(
        channelId: 'UC1',
        channelUrl: 'http://www.youtube.com/channel/UC1',
        channelTitle: 'First',
      );
      final saved = encodeTakeoutCsvs(
        const TakeoutData(
          comments: [],
          liveChats: [],
          subscriptionsByChannelId: {'UC1': sub},
        ),
      );
      final bytes = saved.entries
          .singleWhere((e) => e.key.endsWith('subscriptions.csv'))
          .value;

      expect(parser.parseSubscriptionsCsv(bytes), [sub]);
    });

    test('reads columns it can name by name, leaving the rest empty', () {
      const csv =
          'Channel Title,Channel Id,Kanal-URL\r\n'
          'First,UC1,http://www.youtube.com/channel/UC1\r\n';

      expect(parser.parseSubscriptionsCsv(_toBytes(csv)), [
        const Subscription(
          channelId: 'UC1',
          channelUrl: '',
          channelTitle: 'First',
        ),
      ]);
    });

    test("reads columns in Google's order when it can name none", () {
      const csv =
          'Kanal-ID,Kanal-URL,Kanaltitel\r\n'
          'UC1,http://www.youtube.com/channel/UC1,First\r\n';

      expect(parser.parseSubscriptionsCsv(_toBytes(csv)), [
        const Subscription(
          channelId: 'UC1',
          channelUrl: 'http://www.youtube.com/channel/UC1',
          channelTitle: 'First',
        ),
      ]);
    });

    test('reads columns by their names', () {
      const csv =
          'Channel Title,Channel Id,Channel Url\r\n'
          'First,UC1,http://www.youtube.com/channel/UC1\r\n';

      expect(parser.parseSubscriptionsCsv(_toBytes(csv)), [
        const Subscription(
          channelId: 'UC1',
          channelUrl: 'http://www.youtube.com/channel/UC1',
          channelTitle: 'First',
        ),
      ]);
    });
  });
}
