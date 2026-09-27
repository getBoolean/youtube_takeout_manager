import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
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
}
