import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_import_planner.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_import_service.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';

const _dir = 'Takeout/YouTube and YouTube Music';
const _comments = '$_dir/comments/comments.csv';
String _commentsPage(int n) => '$_dir/comments/comments($n).csv';
const _liveChats = '$_dir/live chats/live chats.csv';
const _subscriptions = '$_dir/subscriptions/subscriptions.csv';

String _commentsCsv(List<String> rows) => [
  'Comment ID,Channel ID,Comment Create Timestamp,Price,Parent Comment ID,'
      'Post ID,Video ID,Comment Text,Top-Level Comment ID',
  ...rows,
].join('\r\n');

String _c(String id, String createdAt, {String channel = 'UCme'}) =>
    '$id,$channel,$createdAt,0,,,vid1,"{""text"":""$id text""}",';

String _liveChatsCsv(List<String> rows) => [
  'Live Chat ID,Channel ID,Live Chat Create Timestamp,Price,Video ID,'
      'Live Chat Text',
  ...rows,
].join('\r\n');

String _l(String id, String createdAt, {String channel = 'UCme'}) =>
    '$id,$channel,$createdAt,0,live1,"{""text"":""$id text""}"';

PickedZip _zip(String name, Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile.string(path, content));
  });
  return (name: name, bytes: ZipEncoder().encodeBytes(archive));
}

Comment _savedComment(
  String id,
  String createdAt, {
  String channel = 'UCme',
  String text = 'saved text',
}) => Comment(
  commentId: id,
  channelId: channel,
  createdAt: DateTime.parse(createdAt),
  price: 0,
  videoId: 'vid1',
  rawCommentText: '{"text":"$text"}',
  displayText: text,
);

LiveChat _savedLiveChat(String id, String createdAt) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime.parse(createdAt),
  price: 0,
  videoId: 'live1',
  rawText: '{"text":"saved"}',
  displayText: 'saved',
);

/// Saved data as the app saves it: each kind remembers when its newest
/// takeout was exported and whether that takeout was [complete]. A null
/// [complete] leaves that out, like data saved before it was tracked.
TakeoutData _saved({
  List<Comment> comments = const [],
  List<LiveChat> liveChats = const [],
  Map<String, Subscription> subscriptions = const {},
  DateTime? latestExportAt,
  bool? complete = true,
}) {
  KindSnapshot? snapshot(List<Object> items) =>
      latestExportAt != null && complete != null && items.isNotEmpty
      ? KindSnapshot(exportedAt: latestExportAt, complete: complete)
      : null;
  return TakeoutData(
    comments: comments,
    liveChats: liveChats,
    subscriptionsByChannelId: subscriptions,
    latestExportAt: latestExportAt,
    commentsSnapshot: snapshot(comments),
    liveChatsSnapshot: snapshot(liveChats),
  );
}

TakeoutImportPlan _plan(
  List<PickedZip> zips, {
  TakeoutData? saved,
  bool merge = true,
  Set<String> deletedCommentIds = const {},
  Map<String, Set<String>> savedChannelSets = const {},
  String? activeTakeoutId,
}) => planTakeoutImport((
  zips: zips,
  saved: saved,
  merge: merge,
  deletedCommentIds: deletedCommentIds,
  deletedLiveChatIds: const {},
  savedChannelSets: savedChannelSets,
  activeTakeoutId: activeTakeoutId,
));

Set<String> _commentIds(TakeoutImportPlan plan) =>
    plan.mergedData.comments.map((c) => c.commentId).toSet();

/// Saved data from a takeout exported 2026-02-01 holding comments A, B, C.
final _savedAbc = _saved(
  comments: [
    _savedComment('A', '2026-01-01T00:00:00Z'),
    _savedComment('B', '2026-01-02T00:00:00Z'),
    _savedComment('C', '2026-01-03T00:00:00Z'),
  ],
  latestExportAt: DateTime.utc(2026, 2),
);

void main() {
  group('grouping picked zips', () {
    test('split parts of one export are checked as one export', () {
      final plan = _plan([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            _c('C', '2026-01-03T00:00:00Z'),
          ]),
        }),
        _zip('takeout-20260301T000000Z-002 (1).zip', {
          _commentsPage(1): _commentsCsv([_c('D', '2026-02-10T00:00:00Z')]),
        }),
      ], saved: _savedAbc);

      expect(plan.commentCheckSkipped, isNull);
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

      final plan = _plan([
        _zip('takeout-20260301T000000Z-001.zip', files),
        _zip('takeout-20260301T000000Z-001 (1).zip', files),
      ], saved: _savedAbc);

      expect(plan.commentCheckSkipped, isNull);
      expect(plan.goneCommentIds, {'B'});
    });

    test('a single renamed zip is dated by its newest item', () {
      final plan = _plan([
        _zip('my backup.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            _c('D', '2026-02-10T00:00:00Z'),
          ]),
        }),
      ], saved: _savedAbc);

      expect(plan.goneCommentIds, {'B', 'C'});
      expect(plan.mergedData.latestExportAt, DateTime.utc(2026, 2, 10));
    });

    test('several exports with one lacking a timestamp are rejected', () {
      expect(
        () => _plan([
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
        () => _plan([
          _zip('takeout-20260301T000000Z-001.zip', {'Takeout/other.csv': 'x'}),
        ]),
        throwsA(isA<TakeoutImportException>()),
      );
    });
  });

  group('merging a newer takeout', () {
    final newer = _zip('takeout-20260301T000000Z-001.zip', {
      _comments: _commentsCsv([
        _c('A', '2026-01-01T00:00:00Z'),
        _c('C', '2026-01-03T00:00:00Z'),
        _c('D', '2026-02-10T00:00:00Z'),
      ]),
    });

    test('adds new items once and marks missing ones deleted', () {
      final plan = _plan([newer], saved: _savedAbc);

      expect(plan.mergedData.comments.map((c) => c.commentId), [
        'D',
        'C',
        'B',
        'A',
      ]);
      expect(plan.newCommentCount, 1);
      expect(plan.goneCommentIds, {'B'});
      expect(plan.newlyDeletedCommentCount, 1);
    });

    test('the newer text replaces the saved text', () {
      final plan = _plan([newer], saved: _savedAbc);

      final a = plan.mergedData.comments.firstWhere((c) => c.commentId == 'A');
      expect(a.displayText, 'A text');
    });

    test('items already deleted are not counted as newly deleted', () {
      final plan = _plan([newer], saved: _savedAbc, deletedCommentIds: {'B'});

      expect(plan.goneCommentIds, {'B'});
      expect(plan.newlyDeletedCommentCount, 0);
    });

    test('adding the same takeout again changes nothing', () {
      final export = _zip('takeout-20260201T000000Z-001.zip', {
        _comments: _commentsCsv([
          _c('A', '2026-01-01T00:00:00Z'),
          _c('B', '2026-01-02T00:00:00Z'),
          _c('C', '2026-01-03T00:00:00Z'),
        ]),
      });

      final plan = _plan([export], saved: _savedAbc);

      expect(plan.newCommentCount, 0);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('items created after the newest snapshot are not marked', () {
      // Saved data can hold items created shortly after its export time,
      // because a takeout is collected after it is requested.
      final saved = _saved(
        comments: [
          _savedComment('A', '2026-01-01T00:00:00Z'),
          _savedComment('B', '2026-01-02T00:00:00Z'),
          _savedComment('Late', '2026-03-02T00:00:00Z'),
        ],
        latestExportAt: DateTime.utc(2026, 3),
      );

      final plan = _plan([
        _zip('renamed.zip', {
          _comments: _commentsCsv([_c('A', '2026-03-01T12:00:00Z')]),
        }),
      ], saved: saved);

      expect(plan.goneCommentIds, {'B'});
    });

    test('a takeout without live chat files leaves live chats alone', () {
      final saved = _saved(
        comments: [_savedComment('A', '2026-01-01T00:00:00Z')],
        liveChats: [_savedLiveChat('L1', '2026-01-01T00:00:00Z')],
        latestExportAt: DateTime.utc(2026, 2),
      );

      final plan = _plan([newer], saved: saved);

      expect(plan.goneLiveChatIds, isEmpty);
      expect(plan.mergedData.liveChats.map((l) => l.liveChatId), ['L1']);
    });

    test('an empty live chat file marks every saved live chat deleted', () {
      final saved = _saved(
        comments: [_savedComment('A', '2026-01-01T00:00:00Z')],
        liveChats: [
          _savedLiveChat('L1', '2026-01-01T00:00:00Z'),
          _savedLiveChat('L2', '2026-01-02T00:00:00Z'),
        ],
        latestExportAt: DateTime.utc(2026, 2),
      );

      final plan = _plan([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
          _liveChats: _liveChatsCsv([]),
        }),
      ], saved: saved);

      expect(plan.goneLiveChatIds, {'L1', 'L2'});
    });

    test('subscriptions from both are kept, the newer one winning', () {
      final saved = _saved(
        comments: [_savedComment('A', '2026-01-01T00:00:00Z')],
        subscriptions: {
          'UCold': const Subscription(
            channelId: 'UCold',
            channelUrl: 'url-old',
            channelTitle: 'Old',
          ),
          'UCboth': const Subscription(
            channelId: 'UCboth',
            channelUrl: 'url-both',
            channelTitle: 'Before rename',
          ),
        },
        latestExportAt: DateTime.utc(2026, 2),
      );

      final plan = _plan([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
          _subscriptions:
              'Channel Id,Channel Url,Channel Title\r\n'
              'UCboth,url-both,After rename',
        }),
      ], saved: saved);

      final subs = plan.mergedData.subscriptionsByChannelId;
      expect(subs.keys, unorderedEquals(['UCold', 'UCboth']));
      expect(subs['UCboth']!.channelTitle, 'After rename');
    });

    test('the merged data is saved with the newest export time', () {
      final plan = _plan([newer], saved: _savedAbc);

      final reloaded = parseCsvFiles(plan.csvFiles);
      expect(reloaded.comments.map((c) => c.commentId), ['D', 'C', 'B', 'A']);
      expect(reloaded.latestExportAt, DateTime.utc(2026, 3));
    });
  });

  group('merging an older takeout', () {
    final saved = _saved(
      comments: [
        _savedComment('A', '2026-01-01T00:00:00Z', text: 'edited'),
        _savedComment('C', '2026-02-15T00:00:00Z'),
      ],
      latestExportAt: DateTime.utc(2026, 3),
    );
    final older = _zip('takeout-20260201T000000Z-001.zip', {
      _comments: _commentsCsv([
        _c('A', '2026-01-01T00:00:00Z'),
        _c('B', '2026-01-02T00:00:00Z'),
      ]),
    });

    test('marks only the items that vanished before the saved takeout', () {
      final plan = _plan([older], saved: saved);

      expect(_commentIds(plan), {'A', 'B', 'C'});
      expect(plan.goneCommentIds, {'B'});
      expect(plan.mergedData.latestExportAt, DateTime.utc(2026, 3));
    });

    test('keeps the saved text', () {
      final plan = _plan([older], saved: saved);

      final a = plan.mergedData.comments.firstWhere((c) => c.commentId == 'A');
      expect(a.displayText, 'edited');
    });
  });

  group('incomplete takeouts skip the deletion check', () {
    Map<String, String> pages(Map<int, List<String>> rowsByPage) => {
      for (final MapEntry(key: n, value: rows) in rowsByPage.entries)
        n == 0 ? _comments : _commentsPage(n): _commentsCsv(rows),
    };

    TakeoutImportPlan planWith(Map<String, String> files) => _plan([
      _zip('takeout-20260301T000000Z-001.zip', files),
    ], saved: _savedAbc);

    test('when a numbered file is missing', () {
      final plan = planWith(
        pages({
          0: [_c('A', '2026-01-01T00:00:00Z'), _c('D', '2026-02-10T00:00:00Z')],
          2: [_c('E', '2025-12-01T00:00:00Z')],
        }),
      );

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
      expect(_commentIds(plan), containsAll(['A', 'B', 'C', 'D', 'E']));
    });

    test('when the first file is missing', () {
      final plan = planWith(
        pages({
          1: [_c('A', '2026-01-01T00:00:00Z')],
        }),
      );

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('when every file is full, so the short last file is missing', () {
      final plan = planWith(
        pages({
          0: [_c('A', '2026-01-01T00:00:00Z'), _c('D', '2026-02-10T00:00:00Z')],
          1: [_c('E', '2025-12-01T00:00:00Z'), _c('F', '2025-11-01T00:00:00Z')],
        }),
      );

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('when an earlier file is short but the last file is full', () {
      // Only the last file is short in a complete takeout, so a full last
      // file means the files after it are missing.
      final plan = planWith(
        pages({
          0: [_c('A', '2026-01-01T00:00:00Z')],
          1: [_c('E', '2025-12-01T00:00:00Z'), _c('F', '2025-11-01T00:00:00Z')],
        }),
      );

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('when some rows could not be read', () {
      final plan = planWith({
        _comments: _commentsCsv([
          _c('A', '2026-01-01T00:00:00Z'),
          'broken,row',
        ]),
      });

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.unparsedRows);
      expect(plan.goneCommentIds, isEmpty);
      expect(plan.mergedData.skippedCommentRows, 1);
    });

    test('when a lone file is as full as a takeout file gets', () {
      final plan = planWith({
        _comments: _commentsCsv([
          for (var i = 0; i < 200; i++) _c('P$i', '2025-06-01T00:00:00Z'),
        ]),
      });

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });
  });

  group('saved data that may be incomplete', () {
    /// Saves [zips] as a first import, the way the app reloads them.
    TakeoutData imported(List<PickedZip> zips) =>
        parseCsvFiles(_plan(zips, merge: false).csvFiles);

    final olderWithB = _zip('takeout-20260201T000000Z-001.zip', {
      _comments: _commentsCsv([
        _c('A', '2026-01-01T00:00:00Z'),
        _c('B', '2026-01-02T00:00:00Z'),
      ]),
    });

    test('keeps an older takeout from marking items after an incomplete '
        'one', () {
      // Every file is full, so the short last file (with B) is missing.
      final saved = imported([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            _c('D', '2026-02-10T00:00:00Z'),
          ]),
          _commentsPage(1): _commentsCsv([
            _c('E', '2025-12-01T00:00:00Z'),
            _c('F', '2025-11-01T00:00:00Z'),
          ]),
        }),
      ]);

      final plan = _plan([olderWithB], saved: saved);

      expect(
        plan.commentCheckSkipped,
        DeletionCheckSkipReason.savedDataUnverified,
      );
      expect(plan.goneCommentIds, isEmpty);
    });

    test('keeps an older takeout from marking items after one with '
        'unreadable rows', () {
      final saved = imported([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            'broken,row',
          ]),
        }),
      ]);

      final plan = _plan([olderWithB], saved: saved);

      expect(
        plan.commentCheckSkipped,
        DeletionCheckSkipReason.savedDataUnverified,
      );
      expect(plan.goneCommentIds, isEmpty);
    });

    test('saved before completeness was tracked is not trusted', () {
      final saved = _saved(
        comments: [_savedComment('A', '2026-01-01T00:00:00Z')],
        latestExportAt: DateTime.utc(2026, 3),
        complete: null,
      );

      final plan = _plan([olderWithB], saved: saved);

      expect(
        plan.commentCheckSkipped,
        DeletionCheckSkipReason.savedDataUnverified,
      );
      expect(plan.goneCommentIds, isEmpty);
    });

    test('a newer takeout without comments leaves their export time alone', () {
      // Comments were last exported Jan 15; a Mar 1 export only had live
      // chats. A Feb 1 export's comments are then the newest comments.
      final january = imported([
        _zip('takeout-20260115T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            _c('B', '2026-01-02T00:00:00Z'),
          ]),
        }),
      ]);
      final march = parseCsvFiles(
        _plan([
          _zip('takeout-20260301T000000Z-001.zip', {
            _liveChats: _liveChatsCsv([_l('L1', '2026-02-20T00:00:00Z')]),
          }),
        ], saved: january).csvFiles,
      );

      final plan = _plan([
        _zip('takeout-20260201T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            _c('B', '2026-01-02T00:00:00Z'),
            _c('C', '2026-01-20T00:00:00Z'),
          ]),
        }),
      ], saved: march);

      expect(plan.goneCommentIds, isEmpty);
      expect(_commentIds(plan), {'A', 'B', 'C'});
    });
  });

  group('account check', () {
    TakeoutImportPlan add(
      List<String> commentRows, {
      List<String>? liveChats,
    }) => _plan([
      _zip('takeout-20260301T000000Z-001.zip', {
        _comments: _commentsCsv(commentRows),
        if (liveChats != null) _liveChats: _liveChatsCsv(liveChats),
      }),
    ], saved: _savedAbc);

    test('adding a takeout from another channel is rejected', () {
      expect(
        () => add([_c('A', '2026-01-01T00:00:00Z', channel: 'UCother')]),
        throwsA(
          isA<TakeoutAccountMismatchException>()
              .having((e) => e.expectedChannelIds, 'expected', {'UCme'})
              .having((e) => e.foundChannelIds, 'found', {'UCother'}),
        ),
      );
    });

    test("the plan is for the takeout's channel", () {
      expect(add([_c('A', '2026-01-01T00:00:00Z')]).accountId, 'UCme');
    });

    test('a takeout whose channel ID is not a channel ID is rejected', () {
      expect(
        () => _plan([
          _zip('takeout-20260301T000000Z-001.zip', {
            _comments: _commentsCsv([
              _c('A', '2026-01-01T00:00:00Z', channel: '../UCme'),
            ]),
          }),
        ], merge: false),
        throwsA(isA<TakeoutImportException>()),
      );
    });

    test('adding a takeout with another of its channels too is accepted', () {
      final plan = add(
        [_c('A', '2026-01-01T00:00:00Z')],
        liveChats: [_l('L1', '2026-01-01T00:00:00Z', channel: 'UCother')],
      );
      expect(plan.accountId, 'UCme');
      expect(plan.channels.map((c) => c.channelId), ['UCme', 'UCother']);
    });

    for (final merge in [true, false]) {
      final action = merge ? 'adding' : 'replacing with';
      test('$action a takeout without comments or live chats is rejected', () {
        expect(
          () => _plan(
            [
              _zip('takeout-20260301T000000Z-001.zip', {
                _subscriptions:
                    'Channel Id,Channel Url,Channel Title\r\nUCs,u,S',
              }),
            ],
            saved: _savedAbc,
            merge: merge,
          ),
          throwsA(isA<TakeoutImportException>()),
        );
      });
    }

    test('adding a takeout of another channel in the saved data merges '
        'into it', () {
      final mixed = _saved(
        comments: [
          _savedComment('A', '2026-01-01T00:00:00Z', channel: 'UCaaa'),
          _savedComment('B', '2026-01-02T00:00:00Z', channel: 'UCaaa'),
          _savedComment('X', '2026-01-03T00:00:00Z', channel: 'UCbbb'),
        ],
        latestExportAt: DateTime.utc(2026, 2),
      );

      final plan = _plan([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('X', '2026-01-03T00:00:00Z', channel: 'UCbbb'),
          ]),
        }),
      ], saved: mixed);

      expect(plan.accountId, 'UCaaa');
      // UCaaa isn't in the newer takeout, so its items can't be found gone.
      expect(plan.goneCommentIds, isEmpty);
    });

    test("other channels' items in saved data are never marked deleted", () {
      final mixed = _saved(
        comments: [
          _savedComment('A', '2026-01-01T00:00:00Z', channel: 'UCaaa'),
          _savedComment('B', '2026-01-02T00:00:00Z', channel: 'UCaaa'),
          _savedComment('X', '2026-01-03T00:00:00Z', channel: 'UCbbb'),
        ],
        latestExportAt: DateTime.utc(2026, 2),
      );

      final plan = _plan([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z', channel: 'UCaaa'),
          ]),
        }),
      ], saved: mixed);

      expect(plan.goneCommentIds, {'B'});
    });

    test('picking takeouts from two channels is rejected', () {
      expect(
        () => _plan([
          _zip('takeout-20260101T000000Z-001.zip', {
            _comments: _commentsCsv([_c('A', '2025-12-01T00:00:00Z')]),
          }),
          _zip('takeout-20260301T000000Z-001.zip', {
            _comments: _commentsCsv([
              _c('B', '2026-02-01T00:00:00Z', channel: 'UCother'),
            ]),
          }),
        ], merge: false),
        throwsA(isA<TakeoutAccountMismatchException>()),
      );
    });

    test("replacing with another channel's takeout is allowed", () {
      final plan = _plan(
        [
          _zip('takeout-20260301T000000Z-001.zip', {
            _comments: _commentsCsv([
              _c('Z', '2026-01-01T00:00:00Z', channel: 'UCother'),
            ]),
          }),
        ],
        saved: _savedAbc,
        merge: false,
      );

      expect(plan.accountId, 'UCother');
      expect(_commentIds(plan), {'Z'});
      expect(plan.goneCommentIds, isEmpty);
    });
  });

  group('replacing', () {
    test('drops the saved data', () {
      final plan = _plan(
        [
          _zip('takeout-20260301T000000Z-001.zip', {
            _comments: _commentsCsv([_c('D', '2026-02-10T00:00:00Z')]),
          }),
        ],
        saved: _savedAbc,
        merge: false,
      );

      expect(_commentIds(plan), {'D'});
      expect(plan.goneCommentIds, isEmpty);
    });

    test('with two takeouts marks items missing from the newer one', () {
      final plan = _plan([
        _zip('takeout-20260301T000000Z-001.zip', {
          _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
        }),
        _zip('takeout-20260201T000000Z-001.zip', {
          _comments: _commentsCsv([
            _c('A', '2026-01-01T00:00:00Z'),
            _c('B', '2026-01-02T00:00:00Z'),
          ]),
        }),
      ], merge: false);

      expect(_commentIds(plan), {'A', 'B'});
      expect(plan.goneCommentIds, {'B'});
      expect(plan.mergedData.latestExportAt, DateTime.utc(2026, 3));
    });
  });

  test("the newest takeout's channel titles win", () {
    String channelCsv(String title) =>
        'Channel ID,Channel Title (Original)\r\nUCme,$title\r\n';
    final plan = _plan([
      _zip('takeout-20260301T000000Z-001.zip', {
        _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
        '$_dir/channels/channel.csv': channelCsv('New name'),
      }),
      _zip('takeout-20260201T000000Z-001.zip', {
        _comments: _commentsCsv([_c('A', '2026-01-01T00:00:00Z')]),
        '$_dir/channels/channel.csv': channelCsv('Old name'),
      }),
    ], merge: false);

    expect(plan.mergedData.ownChannels['UCme']?.title, 'New name');
  });

  group('takeouts with several channels', () {
    const channels = '$_dir/channels/channel.csv';
    String channelList(List<String> ids) => [
      'Channel ID,Channel Title (Original)',
      ...ids.map((id) => '$id,T'),
    ].join('\r\n');

    PickedZip export(
      List<String> commentRows, {
      List<String>? listed,
      String name = 'takeout-20260301T000000Z-001.zip',
    }) => _zip(name, {
      _comments: _commentsCsv(commentRows),
      if (listed != null) channels: channelList(listed),
    });

    test('is saved under the channel its list names', () {
      final plan = _plan([
        export(
          [
            _c('A', '2026-01-01T00:00:00Z', channel: 'UCalt'),
            _c('B', '2026-01-02T00:00:00Z', channel: 'UCalt'),
            _c('C', '2026-01-03T00:00:00Z', channel: 'UCmain'),
          ],
          listed: ['UCmain'],
        ),
      ], merge: false);

      expect(plan.accountId, 'UCmain');
      expect(plan.channels.map((c) => c.channelId), ['UCmain', 'UCalt']);
    });

    test(
      'without a channel list, is saved under the channel that wrote most',
      () {
        final plan = _plan([
          export([
            _c('A', '2026-01-01T00:00:00Z', channel: 'UCa'),
            _c('B', '2026-01-02T00:00:00Z', channel: 'UCa'),
            _c('C', '2026-01-03T00:00:00Z', channel: 'UCb'),
          ]),
        ], merge: false);

        expect(plan.accountId, 'UCa');
      },
    );

    test('goes into the saved takeout it shares a channel with', () {
      final plan = _plan(
        [
          export([_c('A', '2026-01-01T00:00:00Z', channel: 'UCalt')]),
        ],
        merge: false,
        savedChannelSets: {
          'UCmain': {'UCmain', 'UCalt'},
          'UCviewed': {'UCviewed'},
        },
        activeTakeoutId: 'UCviewed',
      );

      expect(plan.accountId, 'UCmain');
    });

    test('sharing channels with two saved takeouts is refused', () {
      expect(
        () => _plan(
          [
            export([
              _c('A', '2026-01-01T00:00:00Z', channel: 'UCa'),
              _c('B', '2026-01-01T00:00:00Z', channel: 'UCb'),
            ]),
          ],
          merge: false,
          savedChannelSets: {
            'UCa': {'UCa'},
            'UCb': {'UCb'},
          },
        ),
        throwsA(isA<TakeoutAccountMismatchException>()),
      );
    });

    test('exports naming different main channels are refused together', () {
      expect(
        () => _plan([
          export(
            [_c('A', '2026-01-01T00:00:00Z', channel: 'UCshared')],
            listed: ['UCa'],
            name: 'takeout-20260101T000000Z-001.zip',
          ),
          export(
            [_c('B', '2026-02-01T00:00:00Z', channel: 'UCshared')],
            listed: ['UCb'],
          ),
        ], merge: false),
        throwsA(isA<TakeoutAccountMismatchException>()),
      );
    });

    test("only channels in the newest takeout can have items found gone", () {
      final saved = _saved(
        comments: [
          _savedComment('A', '2026-01-01T00:00:00Z', channel: 'UCmain'),
          _savedComment('B', '2026-01-02T00:00:00Z', channel: 'UCalt'),
        ],
        latestExportAt: DateTime.utc(2026, 2),
      );

      // UCalt was moved to another account, so this takeout lacks it.
      final plan = _plan(
        [
          export([], listed: ['UCmain']),
        ],
        saved: saved,
        activeTakeoutId: 'UCmain',
        savedChannelSets: {
          'UCmain': {'UCmain', 'UCalt'},
        },
      );

      expect(plan.goneCommentIds, {'A'});
    });

    test(
      "a channel the newest takeout lists has its missing items found gone",
      () {
        final saved = _saved(
          comments: [
            _savedComment('A', '2026-01-01T00:00:00Z', channel: 'UCmain'),
            _savedComment('B', '2026-01-02T00:00:00Z', channel: 'UCalt'),
          ],
          latestExportAt: DateTime.utc(2026, 2),
        );

        final plan = _plan(
          [
            export(
              [_c('A', '2026-01-01T00:00:00Z', channel: 'UCmain')],
              listed: ['UCmain', 'UCalt'],
            ),
          ],
          saved: saved,
          activeTakeoutId: 'UCmain',
          savedChannelSets: {
            'UCmain': {'UCmain', 'UCalt'},
          },
        );

        expect(plan.goneCommentIds, {'B'});
      },
    );

    test('a refusal names channels by the titles the takeouts give', () {
      expect(
        () => _plan([
          export(
            [_c('A', '2026-01-01T00:00:00Z', channel: 'UCa')],
            listed: ['UCa'],
            name: 'takeout-20260101T000000Z-001.zip',
          ),
          export(
            [_c('B', '2026-02-01T00:00:00Z', channel: 'UCb')],
            listed: ['UCb'],
          ),
        ], merge: false),
        throwsA(
          isA<TakeoutAccountMismatchException>().having(
            (e) => e.titlesById,
            'titles',
            {'UCa': 'T', 'UCb': 'T'},
          ),
        ),
      );
    });
  });
}
