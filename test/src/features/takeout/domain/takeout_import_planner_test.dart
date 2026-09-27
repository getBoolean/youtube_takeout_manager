import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/own_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/subscription.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_export.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_planner.dart';

Comment _comment(
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

LiveChat _liveChat(String id, String createdAt) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime.parse(createdAt),
  price: 0,
  videoId: 'live1',
  rawText: '{"text":"saved"}',
  displayText: 'saved',
);

/// A picked export made at [at]. Its comments and live chats each come in
/// one complete file when given, unless [commentPages] says how they were
/// split.
TakeoutExport _export({
  DateTime? at,
  List<Comment>? comments,
  List<LiveChat>? liveChats,
  CsvPages? commentPages,
  CsvPages? liveChatPages,
  int skippedCommentRows = 0,
  int skippedLiveChatRows = 0,
  Map<String, Subscription> subscriptions = const {},
  List<String> listed = const [],
}) => TakeoutExport(
  exportedAt: at,
  data: TakeoutData(
    comments: comments ?? const [],
    liveChats: liveChats ?? const [],
    subscriptionsByChannelId: subscriptions,
    skippedCommentRows: skippedCommentRows,
    skippedLiveChatRows: skippedLiveChatRows,
    ownChannels: {
      for (final id in listed)
        id: OwnChannel(channelId: id, title: 'Title $id'),
    },
  ),
  commentPages:
      commentPages ??
      {
        if (comments != null)
          (page: 0, rows: comments.length + skippedCommentRows),
      },
  liveChatPages:
      liveChatPages ??
      {
        if (liveChats != null)
          (page: 0, rows: liveChats.length + skippedLiveChatRows),
      },
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
  List<TakeoutExport> exports, {
  TakeoutData? saved,
  bool merge = true,
  Set<String> deletedCommentIds = const {},
  Map<String, Set<String>> savedChannelSets = const {},
  String? activeTakeoutId,
}) => planTakeoutImport(exports, (
  saved: saved,
  merge: merge,
  deletedCommentIds: deletedCommentIds,
  deletedLiveChatIds: const {},
  savedChannelSets: savedChannelSets,
  activeTakeoutId: activeTakeoutId,
));

Set<String> _commentIds(TakeoutImportPlan plan) =>
    plan.mergedData.comments.map((c) => c.commentId).toSet();

final _jan = DateTime.utc(2026);
final _feb = DateTime.utc(2026, 2);
final _mar = DateTime.utc(2026, 3);

/// Saved data from a takeout exported 2026-02-01 holding comments A, B, C.
final _savedAbc = _saved(
  comments: [
    _comment('A', '2026-01-01T00:00:00Z'),
    _comment('B', '2026-01-02T00:00:00Z'),
    _comment('C', '2026-01-03T00:00:00Z'),
  ],
  latestExportAt: _feb,
);

void main() {
  test('an export without an export time is dated by its newest item', () {
    final plan = _plan([
      _export(
        comments: [
          _comment('A', '2026-01-01T00:00:00Z'),
          _comment('D', '2026-02-10T00:00:00Z'),
        ],
      ),
    ], saved: _savedAbc);

    expect(plan.goneCommentIds, {'B', 'C'});
    expect(plan.mergedData.latestExportAt, DateTime.utc(2026, 2, 10));
  });

  group('merging a newer takeout', () {
    final newer = _export(
      at: _mar,
      comments: [
        _comment('A', '2026-01-01T00:00:00Z', text: 'newer text'),
        _comment('C', '2026-01-03T00:00:00Z'),
        _comment('D', '2026-02-10T00:00:00Z'),
      ],
    );

    test('adds new items once and marks missing ones deleted', () {
      final plan = _plan([newer], saved: _savedAbc);

      expect(plan.mergedData.comments.map((c) => c.commentId), [
        'D',
        'C',
        'B',
        'A',
      ]);
      expect(plan.newCommentIds, {'D'});
      expect(plan.goneCommentIds, {'B'});
      expect(plan.newlyDeletedCommentIds, {'B'});
    });

    test('the newer text replaces the saved text', () {
      final plan = _plan([newer], saved: _savedAbc);

      final a = plan.mergedData.comments.firstWhere((c) => c.commentId == 'A');
      expect(a.displayText, 'newer text');
    });

    test('items already deleted are not counted as newly deleted', () {
      final plan = _plan([newer], saved: _savedAbc, deletedCommentIds: {'B'});

      expect(plan.goneCommentIds, {'B'});
      expect(plan.newlyDeletedCommentIds, isEmpty);
    });

    test('adding the same takeout again changes nothing', () {
      final export = _export(at: _feb, comments: _savedAbc.comments);

      final plan = _plan([export], saved: _savedAbc);

      expect(plan.newCommentIds, isEmpty);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('items created after the newest snapshot are not marked', () {
      // Saved data can hold items created shortly after its export time,
      // because a takeout is collected after it is requested.
      final saved = _saved(
        comments: [
          _comment('A', '2026-01-01T00:00:00Z'),
          _comment('B', '2026-01-02T00:00:00Z'),
          _comment('Late', '2026-03-02T00:00:00Z'),
        ],
        latestExportAt: _mar,
      );

      final plan = _plan([
        _export(comments: [_comment('A', '2026-03-01T12:00:00Z')]),
      ], saved: saved);

      expect(plan.goneCommentIds, {'B'});
    });

    test('a takeout without live chat files leaves live chats alone', () {
      final saved = _saved(
        comments: [_comment('A', '2026-01-01T00:00:00Z')],
        liveChats: [_liveChat('L1', '2026-01-01T00:00:00Z')],
        latestExportAt: _feb,
      );

      final plan = _plan([newer], saved: saved);

      expect(plan.goneLiveChatIds, isEmpty);
      expect(plan.mergedData.liveChats.map((l) => l.liveChatId), ['L1']);
    });

    test('an empty live chat file marks every saved live chat deleted', () {
      final saved = _saved(
        comments: [_comment('A', '2026-01-01T00:00:00Z')],
        liveChats: [
          _liveChat('L1', '2026-01-01T00:00:00Z'),
          _liveChat('L2', '2026-01-02T00:00:00Z'),
        ],
        latestExportAt: _feb,
      );

      final plan = _plan([
        _export(
          at: _mar,
          comments: [_comment('A', '2026-01-01T00:00:00Z')],
          liveChats: [],
        ),
      ], saved: saved);

      expect(plan.goneLiveChatIds, {'L1', 'L2'});
    });

    test('subscriptions from both are kept, the newer one winning', () {
      final saved = _saved(
        comments: [_comment('A', '2026-01-01T00:00:00Z')],
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
        latestExportAt: _feb,
      );

      final plan = _plan([
        _export(
          at: _mar,
          comments: [_comment('A', '2026-01-01T00:00:00Z')],
          subscriptions: {
            'UCboth': const Subscription(
              channelId: 'UCboth',
              channelUrl: 'url-both',
              channelTitle: 'After rename',
            ),
          },
        ),
      ], saved: saved);

      final subs = plan.mergedData.subscriptionsByChannelId;
      expect(subs.keys, unorderedEquals(['UCold', 'UCboth']));
      expect(subs['UCboth']!.channelTitle, 'After rename');
    });

    test('the merged data has the newest export time', () {
      final plan = _plan([newer], saved: _savedAbc);

      expect(plan.mergedData.latestExportAt, _mar);
      expect(
        plan.mergedData.commentsSnapshot,
        KindSnapshot(exportedAt: _mar, complete: true),
      );
    });
  });

  group('merging an older takeout', () {
    final saved = _saved(
      comments: [
        _comment('A', '2026-01-01T00:00:00Z', text: 'edited'),
        _comment('C', '2026-02-15T00:00:00Z'),
      ],
      latestExportAt: _mar,
    );
    final older = _export(
      at: _feb,
      comments: [
        _comment('A', '2026-01-01T00:00:00Z', text: 'older text'),
        _comment('B', '2026-01-02T00:00:00Z'),
      ],
    );

    test('marks only the items that vanished before the saved takeout', () {
      final plan = _plan([older], saved: saved);

      expect(_commentIds(plan), {'A', 'B', 'C'});
      expect(plan.goneCommentIds, {'B'});
      expect(plan.mergedData.latestExportAt, _mar);
    });

    test('keeps the saved text', () {
      final plan = _plan([older], saved: saved);

      final a = plan.mergedData.comments.firstWhere((c) => c.commentId == 'A');
      expect(a.displayText, 'edited');
    });
  });

  group('incomplete takeouts skip the deletion check', () {
    TakeoutImportPlan planWith(CsvPages pages, {int skippedRows = 0}) => _plan([
      _export(
        at: _mar,
        comments: [
          _comment('A', '2026-01-01T00:00:00Z'),
          _comment('D', '2026-02-10T00:00:00Z'),
        ],
        commentPages: pages,
        skippedCommentRows: skippedRows,
      ),
    ], saved: _savedAbc);

    test('when a numbered file is missing', () {
      final plan = planWith({(page: 0, rows: 2), (page: 2, rows: 1)});

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
      expect(_commentIds(plan), containsAll(['A', 'B', 'C', 'D']));
    });

    test('when the first file is missing', () {
      final plan = planWith({(page: 1, rows: 1)});

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('when every file is full, so the short last file is missing', () {
      final plan = planWith({(page: 0, rows: 2), (page: 1, rows: 2)});

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('when an earlier file is short but the last file is full', () {
      // Only the last file is short in a complete takeout, so a full last
      // file means the files after it are missing.
      final plan = planWith({(page: 0, rows: 1), (page: 1, rows: 2)});

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('when the same file number has different contents', () {
      final plan = planWith({(page: 0, rows: 1), (page: 0, rows: 2)});

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('when some rows could not be read', () {
      final plan = planWith({(page: 0, rows: 3)}, skippedRows: 1);

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.unparsedRows);
      expect(plan.goneCommentIds, isEmpty);
      expect(plan.mergedData.skippedCommentRows, 1);
    });

    test('when a lone file is as full as a takeout file gets', () {
      final plan = planWith({(page: 0, rows: 200)});

      expect(plan.commentCheckSkipped, DeletionCheckSkipReason.incompleteFiles);
      expect(plan.goneCommentIds, isEmpty);
    });

    test('but not when the files are complete', () {
      final plan = planWith({(page: 0, rows: 3), (page: 1, rows: 1)});

      expect(plan.commentCheckSkipped, isNull);
      expect(plan.goneCommentIds, {'B', 'C'});
    });
  });

  group('live chats missing from the newest takeout', () {
    /// Saved live chats L1 and L2 from a takeout exported Feb 1.
    final saved = _saved(
      liveChats: [
        _liveChat('L1', '2026-01-01T00:00:00Z'),
        _liveChat('L2', '2026-01-02T00:00:00Z'),
      ],
      latestExportAt: _feb,
    );

    /// A Mar 1 takeout whose live chats have only L1.
    TakeoutImportPlan planWith({
      CsvPages? pages,
      int skippedRows = 0,
      Set<String> deleted = const {},
    }) => planTakeoutImport(
      [
        _export(
          at: _mar,
          liveChats: [_liveChat('L1', '2026-01-01T00:00:00Z')],
          liveChatPages: pages,
          skippedLiveChatRows: skippedRows,
        ),
      ],
      (
        saved: saved,
        merge: true,
        deletedCommentIds: const {},
        deletedLiveChatIds: deleted,
        savedChannelSets: const {},
        activeTakeoutId: null,
      ),
    );

    test('are marked deleted when the live chat files are complete', () {
      final plan = planWith();

      expect(plan.liveChatCheckSkipped, isNull);
      expect(plan.goneLiveChatIds, {'L2'});
      expect(plan.newlyDeletedLiveChatCount, 1);
    });

    test('already marked ones are not counted as newly deleted', () {
      final plan = planWith(deleted: {'L2'});

      expect(plan.goneLiveChatIds, {'L2'});
      expect(plan.newlyDeletedLiveChatCount, 0);
    });

    test('are left alone when a live chat file is missing', () {
      final plan = planWith(pages: {(page: 0, rows: 1), (page: 2, rows: 1)});

      expect(
        plan.liveChatCheckSkipped,
        DeletionCheckSkipReason.incompleteFiles,
      );
      expect(plan.goneLiveChatIds, isEmpty);
      expect(plan.newlyDeletedLiveChatCount, 0);
      expect(
        plan.mergedData.liveChats.map((l) => l.liveChatId),
        containsAll(['L1', 'L2']),
      );
    });

    test('are left alone when live chat rows could not be read', () {
      final plan = planWith(skippedRows: 1);

      expect(plan.liveChatCheckSkipped, DeletionCheckSkipReason.unparsedRows);
      expect(plan.goneLiveChatIds, isEmpty);
      expect(plan.newlyDeletedLiveChatCount, 0);
      expect(plan.mergedData.skippedLiveChatRows, 1);
    });
  });

  group('saved data that may be incomplete', () {
    /// The data a first import of [exports] saves.
    TakeoutData imported(List<TakeoutExport> exports) =>
        _plan(exports, merge: false).mergedData;

    final olderWithB = _export(
      at: _feb,
      comments: [
        _comment('A', '2026-01-01T00:00:00Z'),
        _comment('B', '2026-01-02T00:00:00Z'),
      ],
    );

    test('keeps an older takeout from marking items after an incomplete '
        'one', () {
      // Every file is full, so the short last file (with B) is missing.
      final saved = imported([
        _export(
          at: _mar,
          comments: [
            _comment('A', '2026-01-01T00:00:00Z'),
            _comment('D', '2026-02-10T00:00:00Z'),
          ],
          commentPages: {(page: 0, rows: 1), (page: 1, rows: 1)},
        ),
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
        _export(
          at: _mar,
          comments: [_comment('A', '2026-01-01T00:00:00Z')],
          skippedCommentRows: 1,
        ),
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
        comments: [_comment('A', '2026-01-01T00:00:00Z')],
        latestExportAt: _mar,
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
        _export(
          at: DateTime.utc(2026, 1, 15),
          comments: [
            _comment('A', '2026-01-01T00:00:00Z'),
            _comment('B', '2026-01-02T00:00:00Z'),
          ],
        ),
      ]);
      final march = _plan([
        _export(at: _mar, liveChats: [_liveChat('L1', '2026-02-20T00:00:00Z')]),
      ], saved: january).mergedData;

      final plan = _plan([
        _export(
          at: _feb,
          comments: [
            _comment('A', '2026-01-01T00:00:00Z'),
            _comment('B', '2026-01-02T00:00:00Z'),
            _comment('C', '2026-01-20T00:00:00Z'),
          ],
        ),
      ], saved: march);

      expect(plan.goneCommentIds, isEmpty);
      expect(_commentIds(plan), {'A', 'B', 'C'});
    });
  });

  group('account check', () {
    TakeoutImportPlan add(
      List<Comment> comments, {
      List<LiveChat>? liveChats,
    }) => _plan([
      _export(at: _mar, comments: comments, liveChats: liveChats),
    ], saved: _savedAbc);

    test('adding a takeout from another channel is rejected, naming both', () {
      expect(
        () => add([_comment('A', '2026-01-01T00:00:00Z', channel: 'UCother')]),
        throwsA(
          isA<TakeoutAccountMismatchException>()
              .having((e) => e.expectedChannelIds, 'expected', {'UCme'})
              .having((e) => e.foundChannelIds, 'found', {'UCother'}),
        ),
      );
    });

    test("the plan is for the takeout's channel", () {
      expect(add([_comment('A', '2026-01-01T00:00:00Z')]).accountId, 'UCme');
    });

    test('a takeout whose channel ID is not a channel ID is rejected', () {
      expect(
        () => _plan([
          _export(
            at: _mar,
            comments: [
              _comment('A', '2026-01-01T00:00:00Z', channel: '../UCme'),
            ],
          ),
        ], merge: false),
        throwsA(isA<TakeoutImportException>()),
      );
    });

    test('adding a takeout with another of its channels too is accepted', () {
      final plan = add(
        [_comment('A', '2026-01-01T00:00:00Z')],
        liveChats: [
          _liveChat(
            'L1',
            '2026-01-01T00:00:00Z',
          ).copyWith(channelId: 'UCother'),
        ],
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
              _export(
                at: _mar,
                subscriptions: {
                  'UCs': const Subscription(
                    channelId: 'UCs',
                    channelUrl: 'u',
                    channelTitle: 'S',
                  ),
                },
              ),
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
          _comment('A', '2026-01-01T00:00:00Z', channel: 'UCaaa'),
          _comment('B', '2026-01-02T00:00:00Z', channel: 'UCaaa'),
          _comment('X', '2026-01-03T00:00:00Z', channel: 'UCbbb'),
        ],
        latestExportAt: _feb,
      );

      final plan = _plan([
        _export(
          at: _mar,
          comments: [_comment('X', '2026-01-03T00:00:00Z', channel: 'UCbbb')],
        ),
      ], saved: mixed);

      expect(plan.accountId, 'UCaaa');
      // UCaaa isn't in the newer takeout, so its items can't be found gone.
      expect(plan.goneCommentIds, isEmpty);
    });

    test("other channels' items in saved data are never marked deleted", () {
      final mixed = _saved(
        comments: [
          _comment('A', '2026-01-01T00:00:00Z', channel: 'UCaaa'),
          _comment('B', '2026-01-02T00:00:00Z', channel: 'UCaaa'),
          _comment('X', '2026-01-03T00:00:00Z', channel: 'UCbbb'),
        ],
        latestExportAt: _feb,
      );

      final plan = _plan([
        _export(
          at: _mar,
          comments: [_comment('A', '2026-01-01T00:00:00Z', channel: 'UCaaa')],
        ),
      ], saved: mixed);

      expect(plan.goneCommentIds, {'B'});
    });

    test('picking takeouts from two channels is rejected', () {
      expect(
        () => _plan([
          _export(at: _jan, comments: [_comment('A', '2025-12-01T00:00:00Z')]),
          _export(
            at: _mar,
            comments: [
              _comment('B', '2026-02-01T00:00:00Z', channel: 'UCother'),
            ],
          ),
        ], merge: false),
        throwsA(isA<TakeoutAccountMismatchException>()),
      );
    });

    test("replacing with another channel's takeout is allowed", () {
      final plan = _plan(
        [
          _export(
            at: _mar,
            comments: [
              _comment('Z', '2026-01-01T00:00:00Z', channel: 'UCother'),
            ],
          ),
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
          _export(at: _mar, comments: [_comment('D', '2026-02-10T00:00:00Z')]),
        ],
        saved: _savedAbc,
        merge: false,
      );

      expect(_commentIds(plan), {'D'});
      expect(plan.goneCommentIds, isEmpty);
    });

    test('with two takeouts marks items missing from the newer one', () {
      final plan = _plan([
        _export(at: _mar, comments: [_comment('A', '2026-01-01T00:00:00Z')]),
        _export(
          at: _feb,
          comments: [
            _comment('A', '2026-01-01T00:00:00Z'),
            _comment('B', '2026-01-02T00:00:00Z'),
          ],
        ),
      ], merge: false);

      expect(_commentIds(plan), {'A', 'B'});
      expect(plan.goneCommentIds, {'B'});
      expect(plan.mergedData.latestExportAt, _mar);
    });
  });

  test("the newest takeout's channel titles win", () {
    TakeoutExport titled(DateTime at, String title) {
      final export = _export(
        at: at,
        comments: [_comment('A', '2026-01-01T00:00:00Z')],
      );
      return TakeoutExport(
        exportedAt: at,
        data: export.data.copyWith(
          ownChannels: {'UCme': OwnChannel(channelId: 'UCme', title: title)},
        ),
        commentPages: export.commentPages,
      );
    }

    final plan = _plan([
      titled(_mar, 'New name'),
      titled(_feb, 'Old name'),
    ], merge: false);

    expect(plan.mergedData.ownChannels['UCme']?.title, 'New name');
  });

  group('takeouts with several channels', () {
    TakeoutExport export(
      List<Comment> comments, {
      List<String> listed = const [],
      DateTime? at,
    }) => _export(at: at ?? _mar, comments: comments, listed: listed);

    test('is saved under the channel its list names', () {
      final plan = _plan([
        export(
          [
            _comment('A', '2026-01-01T00:00:00Z', channel: 'UCalt'),
            _comment('B', '2026-01-02T00:00:00Z', channel: 'UCalt'),
            _comment('C', '2026-01-03T00:00:00Z', channel: 'UCmain'),
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
            _comment('A', '2026-01-01T00:00:00Z', channel: 'UCa'),
            _comment('B', '2026-01-02T00:00:00Z', channel: 'UCa'),
            _comment('C', '2026-01-03T00:00:00Z', channel: 'UCb'),
          ]),
        ], merge: false);

        expect(plan.accountId, 'UCa');
      },
    );

    test('goes into the saved takeout it shares a channel with', () {
      final plan = _plan(
        [
          export([_comment('A', '2026-01-01T00:00:00Z', channel: 'UCalt')]),
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
              _comment('A', '2026-01-01T00:00:00Z', channel: 'UCa'),
              _comment('B', '2026-01-01T00:00:00Z', channel: 'UCb'),
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
            [_comment('A', '2026-01-01T00:00:00Z', channel: 'UCshared')],
            listed: ['UCa'],
            at: _jan,
          ),
          export(
            [_comment('B', '2026-02-01T00:00:00Z', channel: 'UCshared')],
            listed: ['UCb'],
          ),
        ], merge: false),
        throwsA(isA<TakeoutAccountMismatchException>()),
      );
    });

    test('only channels in the newest takeout can have items found gone', () {
      final saved = _saved(
        comments: [
          _comment('A', '2026-01-01T00:00:00Z', channel: 'UCmain'),
          _comment('B', '2026-01-02T00:00:00Z', channel: 'UCalt'),
        ],
        latestExportAt: _feb,
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
      'a channel the newest takeout lists has its missing items found gone',
      () {
        final saved = _saved(
          comments: [
            _comment('A', '2026-01-01T00:00:00Z', channel: 'UCmain'),
            _comment('B', '2026-01-02T00:00:00Z', channel: 'UCalt'),
          ],
          latestExportAt: _feb,
        );

        final plan = _plan(
          [
            export(
              [_comment('A', '2026-01-01T00:00:00Z', channel: 'UCmain')],
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
            [_comment('A', '2026-01-01T00:00:00Z', channel: 'UCa')],
            listed: ['UCa'],
            at: _jan,
          ),
          export(
            [_comment('B', '2026-02-01T00:00:00Z', channel: 'UCb')],
            listed: ['UCb'],
          ),
        ], merge: false),
        throwsA(
          isA<TakeoutAccountMismatchException>().having(
            (e) => e.titlesById,
            'titles',
            {'UCa': 'Title UCa', 'UCb': 'Title UCb'},
          ),
        ),
      );
    });
  });
}
