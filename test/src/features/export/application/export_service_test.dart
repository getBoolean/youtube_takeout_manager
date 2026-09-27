import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/export/application/export_service.dart';
import 'package:youtube_takeout_manager/src/features/export/data/export_file_repository.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';

/// Reads [csv] back as one map per row, keyed by the header row's names.
List<Map<String, String>> _readCsv(String csv) {
  final [header, ...rows] = Csv(autoDetect: false).decode(csv);
  return [
    for (final row in rows)
      {for (var i = 0; i < header.length; i++) '${header[i]}': '${row[i]}'},
  ];
}

const _tricky = 'Hi, "friend"\nsecond line';

final _comment = Comment(
  commentId: 'c1',
  channelId: 'UC1',
  createdAt: DateTime.utc(2026, 1, 2),
  price: 0,
  videoId: 'v1',
  rawCommentText: '',
  displayText: _tricky,
);

final _unnamedComment = Comment(
  commentId: 'c2',
  channelId: 'UCunknown',
  createdAt: DateTime.utc(2026, 1, 3),
  price: 0,
  rawCommentText: '',
  displayText: 'plain',
);

final _paidChat = LiveChat(
  liveChatId: 'l1',
  channelId: 'UC1',
  createdAt: DateTime.utc(2026, 1, 4),
  price: 5,
  currencyCode: 'EUR',
  videoId: 'v2',
  rawText: '',
  displayText: 'thanks',
);

const _names = {'UC1': 'Chan, the "Best"'};

void main() {
  final service = ExportService(ExportFileRepository());

  group('CSV', () {
    Map<String, Map<String, String>> rowsById() => {
      for (final row in _readCsv(
        service.exportToCsv(
          [_comment, _unnamedComment],
          [_paidChat],
          channelNames: _names,
        ),
      ))
        row['ID']!: row,
    };

    test('text with commas, quotes and newlines reads back unchanged', () {
      final rows = rowsById();

      expect(rows['c1']!['Text'], _tricky);
      expect(rows['c1']!['Channel Name'], _names['UC1']);
    });

    test('has a row per comment and live chat', () {
      expect(rowsById().keys, unorderedEquals(['c1', 'c2', 'l1']));
    });

    test('live chats keep their price and currency', () {
      final chat = rowsById()['l1']!;

      expect(num.parse(chat['Price']!), _paidChat.price);
      expect(chat['Currency'], 'EUR');
      expect(chat['Video ID'], 'v2');
    });

    test('a channel without a known name has an empty name', () {
      expect(rowsById()['c2']!['Channel Name'], isEmpty);
    });
  });

  group('JSON', () {
    Map<String, dynamic> decoded() =>
        jsonDecode(
              service.exportToJson(
                [_comment, _unnamedComment],
                [_paidChat],
                channelNames: _names,
              ),
            )
            as Map<String, dynamic>;

    test('has both lists, with each item\'s text and channel name', () {
      final data = decoded();
      final comments = {
        for (final c in data['comments'] as List) c['id']: c as Map,
      };
      final chats = {
        for (final c in data['liveChats'] as List) c['id']: c as Map,
      };

      expect(comments.keys, unorderedEquals(['c1', 'c2']));
      expect(comments['c1']!['text'], _tricky);
      expect(comments['c1']!['channelName'], _names['UC1']);
      expect(comments['c2']!['channelName'], isNull);
      expect(chats.keys, ['l1']);
      expect(chats['l1']!['price'], _paidChat.price);
      expect(chats['l1']!['currency'], 'EUR');
    });
  });

  group('sanitizeFilename', () {
    test('replaces characters files can\'t have, and whitespace', () {
      final name = ExportService.sanitizeFilename('a<b>c:d"e/f\\g|h?i*j k\tl');

      expect(name, isNot(matches(RegExp(r'[<>:"/\\|?*\s]'))));
      // Every letter is kept, in order.
      expect(name.replaceAll('_', ''), 'abcdefghijkl');
    });

    test('leaves an ordinary name alone', () {
      expect(ExportService.sanitizeFilename('Chan_export'), 'Chan_export');
    });
  });
}
