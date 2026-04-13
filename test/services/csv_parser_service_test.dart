import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_takeout_manager/services/csv_parser_service.dart';

Uint8List _toBytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  late CsvParserService parser;

  setUp(() {
    parser = CsvParserService();
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
  });
}
