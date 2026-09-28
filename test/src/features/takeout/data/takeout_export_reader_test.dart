import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_export_reader.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_parser.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_planner.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_request.dart';

const _dir = 'Takeout/YouTube and YouTube Music';
const _comments = '$_dir/comments/comments.csv';
String _commentsPage(int n) => '$_dir/comments/comments($n).csv';

String _commentsCsv(List<String> rows) => [
  'Comment ID,Channel ID,Comment Create Timestamp,Price,Parent Comment ID,'
      'Post ID,Video ID,Comment Text,Top-Level Comment ID',
  ...rows,
].join('\r\n');

String _c(String id, String createdAt, {String channel = 'UCme'}) =>
    '$id,$channel,$createdAt,0,,,vid1,"{""text"":""$id text""}",';

Uint8List _zipBytes(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile.string(path, content));
  });
  return ZipEncoder().encodeBytes(archive);
}

PickedZip _zip(String name, Map<String, String> files) =>
    PickedZip.bytes(name, _zipBytes(files));

Comment _savedComment(String id, String createdAt) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime.parse(createdAt),
  price: 0,
  videoId: 'vid1',
  rawCommentText: '{"text":"saved text"}',
  displayText: 'saved text',
);

/// Saved data from a complete takeout exported 2026-02-01 holding comments
/// A, B, C.
final _savedAbc = TakeoutData(
  comments: [
    _savedComment('A', '2026-01-01T00:00:00Z'),
    _savedComment('B', '2026-01-02T00:00:00Z'),
    _savedComment('C', '2026-01-03T00:00:00Z'),
  ],
  liveChats: const [],
  subscriptionsByChannelId: const {},
  latestExportAt: DateTime.utc(2026, 2),
  commentsSnapshot: KindSnapshot(
    exportedAt: DateTime.utc(2026, 2),
    complete: true,
  ),
);

/// Reads [zips] and plans merging them into [_savedAbc], as an import does.
TakeoutImportPlan _import(List<PickedZip> zips) =>
    planTakeoutImport(readTakeoutExports(zips), (
      saved: _savedAbc,
      merge: true,
      deletedCommentIds: const {},
      deletedLiveChatIds: const {},
      savedChannelSets: const {},
      activeTakeoutId: null,
    ));

void main() {
  test('split parts of one export are read and checked as one export', () {
    final plan = _import([
      _zip('takeout-20260301T000000Z-001.zip', {
        _comments: _commentsCsv([
          _c('A', '2026-01-01T00:00:00Z'),
          _c('C', '2026-01-03T00:00:00Z'),
        ]),
      }),
      _zip('takeout-20260301T000000Z-002 (1).zip', {
        _commentsPage(1): _commentsCsv([_c('D', '2026-02-10T00:00:00Z')]),
      }),
    ]);

    expect(plan.commentCheckSkipped, isNull);
    expect(plan.goneCommentIds, {'B'});
    expect(plan.mergedData.latestExportAt, DateTime.utc(2026, 3));
  });

  test('reads a zip from where it is on disk', () {
    final dir = Directory.systemTemp.createTempSync('takeout_reader');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/takeout-20260301T000000Z-001.zip')
      ..writeAsBytesSync(
        _zipBytes({
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            _c('C', '2026-01-03T00:00:00Z'),
          ]),
          '$_dir/videos/a video.mp4': 'not a CSV',
        }),
      );

    final plan = _import([
      PickedZip.file('takeout-20260301T000000Z-001.zip', file.path),
    ]);

    expect(plan.goneCommentIds, {'B'});
    expect(plan.mergedData.latestExportAt, DateTime.utc(2026, 3));
  });

  test('picking the same zip twice is harmless', () {
    final files = {
      _comments: _commentsCsv([
        _c('A', '2026-01-01T00:00:00Z'),
        _c('C', '2026-01-03T00:00:00Z'),
      ]),
    };

    final plan = _import([
      _zip('takeout-20260301T000000Z-001.zip', files),
      _zip('takeout-20260301T000000Z-001 (1).zip', files),
    ]);

    expect(plan.commentCheckSkipped, isNull);
    expect(plan.goneCommentIds, {'B'});
  });

  test('a renamed zip has no export time', () {
    final exports = readTakeoutExports([
      _zip('my backup.zip', {
        _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
      }),
    ]);

    expect(exports.single.exportedAt, isNull);
    expect(exports.single.commentPages, {(page: 0, rows: 1)});
  });

  test('several exports with one lacking a timestamp are rejected', () {
    expect(
      () => readTakeoutExports([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
        }),
        _zip('renamed.zip', {
          _comments: _commentsCsv([_c('B', '2026-01-02T00:00:00Z')]),
        }),
      ]),
      throwsA(isA<TakeoutImportException>()),
    );
  });

  test('files with no takeout data are rejected', () {
    expect(
      () => readTakeoutExports([
        _zip('takeout-20260301T000000Z-001.zip', {'Takeout/other.csv': 'x'}),
      ]),
      throwsA(isA<TakeoutImportException>()),
    );
  });

  group('a zip part that names no channel', () {
    const subscriptions = {
      '$_dir/subscriptions/subscriptions.csv':
          'Channel Id,Channel Url,Channel Title\r\n'
          'UCsub,http://www.youtube.com/channel/UCsub,A channel\r\n',
      // Parts also hold what the app doesn't read.
      '$_dir/videos/a video.mp4': 'not a CSV',
    };

    TakeoutImportContext context({String? shown, bool merge = false}) => (
      saved: merge ? _savedAbc : null,
      merge: merge,
      deletedCommentIds: const {},
      deletedLiveChatIds: const {},
      savedChannelSets: const {},
      activeTakeoutId: shown,
    );

    test('goes with the account the other parts are from', () {
      final plan = planTakeoutImport(
        readTakeoutExports([
          _zip('takeout-20260301T000000Z-001.zip', {
            _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
          }),
          _zip('takeout-20260301T000000Z-002.zip', subscriptions),
        ]),
        context(shown: 'UCsomeoneElse'),
      );

      expect(plan.accountId, 'UCme');
      expect(plan.accountAssumed, isFalse);
      expect(plan.mergedData.subscriptionsByChannelId, contains('UCsub'));
    });

    test('on its own goes into the takeout shown, to be confirmed', () {
      final plan = planTakeoutImport(
        readTakeoutExports([
          _zip('takeout-20260301T000000Z-002.zip', subscriptions),
        ]),
        context(shown: 'UCme', merge: true),
      );

      expect(plan.accountId, 'UCme');
      expect(plan.accountAssumed, isTrue);
      expect(plan.needsReview, isTrue);
      expect(plan.mergedData.subscriptionsByChannelId, contains('UCsub'));
      expect(plan.goneCommentIds, isEmpty);
    });

    test("is refused when there's no takeout to add it to", () {
      expect(
        () => planTakeoutImport(
          readTakeoutExports([
            _zip('takeout-20260301T000000Z-002.zip', subscriptions),
          ]),
          context(),
        ),
        throwsA(isA<TakeoutImportException>()),
      );
    });
  });

  test('a takeout from another account is refused, naming both', () {
    expect(
      () => _import([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z', channel: 'UCother'),
          ]),
        }),
      ]),
      throwsA(
        isA<TakeoutAccountMismatchException>()
            .having((e) => e.expectedChannelIds, 'expected', {'UCme'})
            .having((e) => e.foundChannelIds, 'found', {'UCother'}),
      ),
    );
  });

  test('the merged data survives a save and reload', () {
    final plan = _import([
      _zip('takeout-20260301T000000Z-001.zip', {
        _comments: _commentsCsv([
          _c('A', '2026-01-01T00:00:00Z'),
          _c('C', '2026-01-03T00:00:00Z'),
          _c('D', '2026-02-10T00:00:00Z'),
        ]),
      }),
    ]);

    final reloaded = parseCsvFiles(encodeTakeoutCsvs(plan.mergedData));

    expect(reloaded.comments.map((c) => c.commentId), ['D', 'C', 'B', 'A']);
    expect(reloaded.latestExportAt, DateTime.utc(2026, 3));
    expect(reloaded.commentsSnapshot, plan.mergedData.commentsSnapshot);
  });

  group('history', () {
    const channelCsv = '$_dir/channels/channel.csv';
    const watchHtml = '$_dir/history/watch-history.html';
    const searchJson = '$_dir/history/search-history.json';
    const myChannel = 'Channel ID,Channel Title (Original)\r\nUCme,Me';

    String watchHistory(List<(String, String)> watches) =>
        '<html><body>${[for (final (id, date) in watches) '<div class="outer-cell"><p class="mdl-typography--title">'
              'YouTube<br></p><div class="content-cell '
              'mdl-typography--body-1">Watched <a href="https://'
              'www.youtube.com/watch?v=$id">Video $id</a><br>$date<br>'
              '</div></div>'].join()}</body></html>';

    WatchEntry savedWatch(String id, DateTime time) => WatchEntry(
      time: time,
      kind: WatchKind.video,
      title: 'Video $id',
      url: 'https://www.youtube.com/watch?v=$id',
    );

    TakeoutImportPlan importWithHistory(
      Map<String, String> files, {
      TakeoutHistory? savedHistory,
      String? shown,
      bool merge = true,
    }) => planTakeoutImport(
      readTakeoutExports([_zip('takeout-20260301T000000Z-001.zip', files)]),
      (
        saved: merge ? _savedAbc : null,
        merge: merge,
        deletedCommentIds: const {},
        deletedLiveChatIds: const {},
        savedChannelSets: const {},
        activeTakeoutId: shown,
      ),
      savedHistory: savedHistory,
    );

    test('watch and search history are read from a takeout zip', () {
      final exports = readTakeoutExports([
        _zip('takeout-20260301T000000Z-001.zip', {
          channelCsv: myChannel,
          watchHtml: watchHistory([('v1', 'Feb 1, 2026, 1:00:00 PM UTC')]),
          searchJson:
              '[{"header": "YouTube", "title": "Searched for cats", '
              '"titleUrl": "https://www.youtube.com/results?search_query=cats", '
              '"time": "2026-02-02T00:00:00Z"}]',
        }),
      ]);

      final history = exports.single.history!;
      expect(history.exportedAt, DateTime.utc(2026, 3));
      expect(history.watches!.entries.single.videoId, 'v1');
      expect(
        history.watches!.entries.single.time,
        DateTime.utc(2026, 2, 1, 13),
      );
      expect(history.searches!.entries.single.query, 'cats');
    });

    test('a takeout with only history goes into the takeout shown, to be '
        'confirmed', () {
      final plan = importWithHistory({
        watchHtml: watchHistory([('v1', 'Feb 1, 2026, 1:00:00 PM UTC')]),
      }, shown: 'UCme');

      expect(plan.accountId, 'UCme');
      expect(plan.accountAssumed, isTrue);
      expect(plan.needsReview, isTrue);
      expect(plan.history.newWatchCount, 1);
      // Having no comments, it can't say any are gone.
      expect(plan.goneCommentIds, isEmpty);
      expect(
        plan.mergedData.comments.map((c) => c.commentId),
        unorderedEquals(['A', 'B', 'C']),
      );
    });

    test('a takeout with only history, read before merging, names the '
        'takeout shown', () {
      final plan = importWithHistory(
        {
          watchHtml: watchHistory([('v1', 'Feb 1, 2026, 1:00:00 PM UTC')]),
        },
        shown: 'UCme',
        merge: false,
      );

      expect(plan.accountId, 'UCme');
      expect(plan.accountAssumed, isTrue);
    });

    test("a takeout with only history is refused when there's no takeout to "
        'add it to', () {
      expect(
        () => importWithHistory({
          watchHtml: watchHistory([('v1', 'Feb 1, 2026, 1:00:00 PM UTC')]),
        }, merge: false),
        throwsA(isA<TakeoutImportException>()),
      );
    });

    test('a part with only history goes with the account the other parts '
        'are from', () {
      final plan = planTakeoutImport(
        readTakeoutExports([
          _zip('takeout-20260301T000000Z-001.zip', {
            _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
          }),
          _zip('takeout-20260401T000000Z-001.zip', {
            watchHtml: watchHistory([('v1', 'Feb 1, 2026, 1:00:00 PM UTC')]),
          }),
        ]),
        (
          saved: null,
          merge: false,
          deletedCommentIds: const {},
          deletedLiveChatIds: const {},
          savedChannelSets: const {},
          activeTakeoutId: 'UCsomeoneElse',
        ),
      );

      expect(plan.accountId, 'UCme');
      expect(plan.accountAssumed, isFalse);
      expect(plan.history.newWatchCount, 1);
    });

    test('merging a takeout without history keeps the saved history', () {
      final plan = importWithHistory(
        {
          _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
        },
        savedHistory: TakeoutHistory(
          watches: [savedWatch('v1', DateTime.utc(2026, 1, 5))],
          watchesSnapshot: DateTime.utc(2026, 2),
        ),
      );

      expect(plan.history.merged, isNull);
      expect(plan.history.needsReview, isFalse);
    });

    test("merging adds the new takeout's history and marks what's gone", () {
      final plan = importWithHistory(
        {
          channelCsv: myChannel,
          watchHtml: watchHistory([
            ('v2', 'Feb 20, 2026, 1:00:00 PM UTC'),
            ('v1', 'Jan 5, 2026, 12:00:00 AM UTC'),
          ]),
        },
        savedHistory: TakeoutHistory(
          watches: [
            savedWatch('v1', DateTime.utc(2026, 1, 5)),
            savedWatch('old', DateTime.utc(2025, 12, 1)),
          ],
          watchesSnapshot: DateTime.utc(2026, 2),
        ),
      );

      expect(plan.history.newWatchCount, 1);
      expect(plan.history.newlyRemovedWatchCount, 1);
      expect(
        [for (final w in plan.history.merged!.watches) w.videoId],
        ['v2', 'v1', 'old'],
      );
    });

    test('unreadable history needs review', () {
      final plan = importWithHistory({
        channelCsv: myChannel,
        watchHtml: watchHistory([('v1', '1 de febrero de 2026, 13:00:00 UTC')]),
      });

      expect(plan.history.unreadableFiles, 1);
      expect(plan.needsReview, isTrue);
    });
  });
}
