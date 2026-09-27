import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/app_effects.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/queue_channel_assignment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_name_resolver.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/legacy_takeout_migration.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_importer.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_remover.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/own_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_request.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';

class _MemoryTakeoutRepository implements TakeoutRepository {
  final accounts = <String, Map<String, Uint8List>>{};
  Map<String, Uint8List>? legacy;

  /// Holds up loading [legacy] until it completes.
  Completer<void>? legacyGate;
  bool failSaves = false;

  @override
  Future<void> saveCsvs(
    String accountId,
    Map<String, Uint8List> csvFiles,
  ) async {
    if (failSaves) throw const FileSystemException('disk full');
    accounts[accountId] = {...csvFiles};
  }

  @override
  Future<Map<String, Uint8List>?> loadCsvs(
    String accountId, {
    bool Function(String path)? only,
  }) async {
    final files = accounts[accountId];
    if (files == null || only == null) return files;
    return {
      for (final MapEntry(:key, :value) in files.entries)
        if (only(key)) key: value,
    };
  }

  @override
  Future<List<String>> listAccountIds() async => accounts.keys.toList();

  @override
  Future<void> clearCsvs(String accountId) async => accounts.remove(accountId);

  @override
  Future<Map<String, Uint8List>?> loadLegacyCsvs() async {
    await legacyGate?.future;
    return legacy;
  }

  @override
  Future<void> clearLegacyCsvs() async => legacy = null;
}

Comment _comment(String id, String createdAt) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime.parse(createdAt),
  price: 0,
  videoId: 'vid1',
  rawCommentText: '{"text":"$id"}',
  displayText: id,
);

/// Saved data from a takeout exported 2026-02-01 holding comments A, B, C.
final _savedAbc = TakeoutData(
  comments: [
    _comment('A', '2026-01-01T00:00:00Z'),
    _comment('B', '2026-01-02T00:00:00Z'),
    _comment('C', '2026-01-03T00:00:00Z'),
  ],
  liveChats: const [],
  subscriptionsByChannelId: const {},
  latestExportAt: DateTime.utc(2026, 2),
);

/// A takeout exported 2026-03-01 where B is gone and D is new.
List<PickedZip> _newerTakeout({String channel = 'UCme'}) {
  String row(String id, String createdAt) =>
      '$id,$channel,$createdAt,0,,,vid1,"{""text"":""$id""}",';
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'Takeout/YouTube and YouTube Music/comments/comments.csv',
        [
          'Comment ID,Channel ID,Comment Create Timestamp,Price,'
              'Parent Comment ID,Post ID,Video ID,Comment Text,'
              'Top-Level Comment ID',
          row('A', '2026-01-01T00:00:00Z'),
          row('C', '2026-01-03T00:00:00Z'),
          row('D', '2026-02-10T00:00:00Z'),
        ].join('\r\n'),
      ),
    );
  return [
    (
      name: 'takeout-20260301T000000Z-001.zip',
      bytes: ZipEncoder().encodeBytes(archive),
    ),
  ];
}

DeletionQueueItem _pending(String itemId) => DeletionQueueItem(
  id: 'q-$itemId',
  itemId: itemId,
  itemType: QueueItemKind.comment,
  status: DeletionItemStatus.pending,
  createdAt: DateTime.utc(2026),
);

void main() {
  late _MemoryTakeoutRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'flutter.active_takeout_account': 'UCme',
    });
    repository = _MemoryTakeoutRepository();
    repository.accounts['UCme'] = encodeTakeoutCsvs(_savedAbc);
  });

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [takeoutRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// A container running the app's start-up effects, the ones that don't
  /// touch takeouts left out.
  ProviderContainer startedApp() {
    final c = ProviderContainer(
      overrides: [
        takeoutRepositoryProvider.overrideWithValue(repository),
        legacySignInMigrationProvider.overrideWith((ref) async {}),
        channelThumbnailFetcherProvider.overrideWith(_Idle.new),
        videoTitleFetcherProvider.overrideWith((ref) => const Stream.empty()),
        emojiNameResolverProvider.overrideWith(_IdleEmoji.new),
      ],
    );
    addTearDown(c.dispose);
    c.listen(appEffectsProvider, (_, _) {});
    return c;
  }

  Future<List<String>> commentIds(ProviderContainer c) async => [
    for (final comment in (await c.read(takeoutProvider.future))!.data.comments)
      comment.commentId,
  ];

  Future<List<String>> queuedItemIds(ProviderContainer c) async => [
    for (final i in await c.read(deletionQueueProvider.future)) i.itemId,
  ];

  Future<Set<String>?> deletedCommentIds(ProviderContainer c) async =>
      (await c.read(deletedIdsProvider.future))[QueueItemKind.comment];

  test(
    'adding a newer takeout merges it and marks missing items deleted',
    () async {
      final c = container();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        _pending('B'),
        _pending('C'),
      ]);
      final notifier = c.read(takeoutImporterProvider.notifier);

      final prepared = await notifier.prepareImport(
        _newerTakeout(),
        merge: true,
      );
      await notifier.commitImport(prepared);

      expect(await commentIds(c), ['D', 'C', 'B', 'A']);
      expect(await deletedCommentIds(c), {'B'});
      expect(await queuedItemIds(c), ['C']);
      expect(
        repository.accounts['UCme'],
        encodeTakeoutCsvs(prepared.plan.mergedData),
      );

      final restarted = container();
      expect(await commentIds(restarted), ['D', 'C', 'B', 'A']);
      expect(
        (await restarted.read(takeoutProvider.future))!.data.latestExportAt,
        DateTime.utc(2026, 3),
      );
      expect(await deletedCommentIds(restarted), {'B'});
    },
  );

  test('items already deleted are not counted as newly deleted', () async {
    final c = container();
    await c
        .read(deletedIdsProvider.notifier)
        .markDeleted(
          DeletionTargets.ids({
            QueueItemKind.comment: {'B'},
          }),
        );

    final (:plan, csvFiles: _) = await c
        .read(takeoutImporterProvider.notifier)
        .prepareImport(_newerTakeout(), merge: true);

    expect(plan.goneCommentIds, {'B'});
    expect(plan.newlyDeletedCommentCount, 0);
  });

  test('a takeout from another account changes nothing', () async {
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([_pending('B')]);
    final savedFiles = repository.accounts['UCme'];

    await expectLater(
      c
          .read(takeoutImporterProvider.notifier)
          .prepareImport(_newerTakeout(channel: 'UCother'), merge: true),
      throwsA(isA<TakeoutAccountMismatchException>()),
    );

    expect(repository.accounts, {'UCme': same(savedFiles)});
    expect(await commentIds(c), unorderedEquals(['A', 'B', 'C']));
    expect(await deletedCommentIds(c), isEmpty);
    expect(await queuedItemIds(c), ['B']);
  });

  test("replacing with another account's takeout saves it separately and "
      'switches to it', () async {
    final c = container();
    final savedFiles = repository.accounts['UCme'];
    final notifier = c.read(takeoutImporterProvider.notifier);

    final prepared = await notifier.prepareImport(
      _newerTakeout(channel: 'UCother'),
      merge: false,
    );
    await notifier.commitImport(prepared);

    expect(prepared.plan.accountId, 'UCother');
    expect(await commentIds(c), ['D', 'C', 'A']);
    expect(repository.accounts['UCme'], same(savedFiles));
    expect(repository.accounts.keys, unorderedEquals(['UCme', 'UCother']));
    expect(await commentIds(container()), ['D', 'C', 'A']);
  });

  test('live chats and subscriptions from a takeout zip survive the import '
      'and a restart', () async {
    const dir = 'Takeout/YouTube and YouTube Music';
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          '$dir/live chats/live chats.csv',
          [
            'Live Chat ID,Channel ID,Live Chat Create Timestamp,Price,'
                'Currency code,Video ID,Live Chat Text',
            'L1,UCme,2026-02-01T10:00:00+00:00,5,USD,live1,'
                '"{""text"":""paid""}"',
            'L2,UCme,2026-02-02T10:00:00+00:00,0,,live1,"{""text"":""hi""}"',
          ].join('\r\n'),
        ),
      )
      ..addFile(
        ArchiveFile.string(
          '$dir/subscriptions/subscriptions.csv',
          [
            'Channel Id,Channel Url,Channel Title',
            'UCsub,http://www.youtube.com/channel/UCsub,"Sub, With Comma"',
          ].join('\r\n'),
        ),
      );
    final zips = [
      ..._newerTakeout(),
      (
        name: 'takeout-20260301T000000Z-002.zip',
        bytes: ZipEncoder().encodeBytes(archive),
      ),
    ];
    final notifier = container().read(takeoutImporterProvider.notifier);

    await notifier.commitImport(
      await notifier.prepareImport(zips, merge: true),
    );

    final restarted = (await container().read(takeoutProvider.future))!.data;
    expect(
      restarted.liveChats.map((l) => (l.liveChatId, l.displayText)),
      unorderedEquals([('L1', 'paid'), ('L2', 'hi')]),
    );
    expect(
      restarted.liveChats.firstWhere((l) => l.liveChatId == 'L1').price,
      5,
    );
    expect(
      restarted.subscriptionsByChannelId['UCsub']?.channelTitle,
      'Sub, With Comma',
    );
    expect(
      restarted.comments.map((c) => c.commentId),
      containsAll(['A', 'C', 'D']),
    );
  });

  test('data saved before per-account storage moves into its account and is '
      'selected once the app starts', () async {
    SharedPreferences.setMockInitialValues({});
    repository.accounts.clear();
    final legacy = encodeTakeoutCsvs(_savedAbc);
    repository.legacy = legacy;
    final c = startedApp();

    await c.read(legacyTakeoutMigrationProvider.future);

    expect(
      await c.read(takeoutSelectionProvider.future),
      const TakeoutSelection(takeoutId: 'UCme'),
    );
    expect(await commentIds(c), unorderedEquals(['A', 'B', 'C']));
    expect(repository.accounts, {'UCme': legacy});
    expect(repository.legacy, isNull);
    expect(await commentIds(container()), unorderedEquals(['A', 'B', 'C']));
  });

  test('items found gone stay marked even if saving fails', () async {
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([_pending('B')]);
    final savedFiles = repository.accounts['UCme'];
    final notifier = c.read(takeoutImporterProvider.notifier);
    final prepared = await notifier.prepareImport(_newerTakeout(), merge: true);

    repository.failSaves = true;
    await expectLater(
      notifier.commitImport(prepared),
      throwsA(isA<FileSystemException>()),
    );

    expect(await deletedCommentIds(c), {'B'});
    expect(await queuedItemIds(c), isEmpty);
    expect(repository.accounts['UCme'], same(savedFiles));
  });

  test('a takeout selected while data saved before per-account storage is '
      'read stays selected', () async {
    SharedPreferences.setMockInitialValues({});
    repository.accounts.clear();
    final legacy = encodeTakeoutCsvs(_savedAbc);
    repository.legacy = legacy;
    final gate = repository.legacyGate = Completer<void>();
    final c = startedApp();
    await pumpEventQueue();

    // As importing another takeout does.
    await c.read(takeoutSelectionProvider.notifier).select('UCother');
    gate.complete();
    await c.read(legacyTakeoutMigrationProvider.future);

    expect(
      c.read(takeoutSelectionProvider).value,
      const TakeoutSelection(takeoutId: 'UCother'),
    );
    expect(repository.accounts, isEmpty);
    expect(repository.legacy, same(legacy));
  });

  test('data saved before per-account storage is left alone while a takeout '
      'is selected', () async {
    final legacy = encodeTakeoutCsvs(_savedAbc);
    repository.legacy = legacy;
    final saved = repository.accounts['UCme'];

    await startedApp().read(legacyTakeoutMigrationProvider.future);

    expect(repository.accounts, {'UCme': same(saved)});
    expect(repository.legacy, same(legacy));
  });

  test('data saved before per-account storage with an odd channel ID stays '
      'where it is, with nothing selected', () async {
    SharedPreferences.setMockInitialValues({});
    repository.accounts.clear();
    final legacy = encodeTakeoutCsvs(
      TakeoutData(
        comments: [
          _comment('A', '2026-01-01T00:00:00Z').copyWith(channelId: 'NUL'),
        ],
        liveChats: const [],
        subscriptionsByChannelId: const {},
      ),
    );
    repository.legacy = legacy;

    final c = startedApp();

    await expectLater(
      c.read(legacyTakeoutMigrationProvider.future),
      throwsA(isA<LegacyTakeoutMigrationException>()),
    );
    // Home then offers to import, rather than showing data tied to no
    // channel.
    expect(await c.read(takeoutSelectionProvider.future), isNull);
    expect(repository.accounts, isEmpty);
    expect(repository.legacy, same(legacy));
  });

  test(
    'saved data no channel wrote can still be replaced by an import',
    () async {
      SharedPreferences.setMockInitialValues({});
      repository.accounts.clear();
      repository.legacy = encodeTakeoutCsvs(
        TakeoutData(
          comments: [
            _comment('A', '2026-01-01T00:00:00Z').copyWith(channelId: 'NUL'),
          ],
          liveChats: const [],
          subscriptionsByChannelId: const {},
        ),
      );
      final c = container();
      c.listen(takeoutProvider, (_, _) {});
      final notifier = c.read(takeoutImporterProvider.notifier);

      final prepared = await notifier.prepareImport(
        _newerTakeout(),
        merge: false,
      );
      await notifier.commitImport(prepared);

      expect(
        (await c.read(takeoutSelectionProvider.future))?.takeoutId,
        'UCme',
      );
      expect(await commentIds(c), ['D', 'C', 'A']);
    },
  );

  test('tells which accounts have saved data', () async {
    final notifier = container().read(takeoutImporterProvider.notifier);

    expect(await notifier.hasSavedData('UCme'), isTrue);
    expect(await notifier.hasSavedData('UCother'), isFalse);
  });

  test('fills in the channel of queued items from before it was saved, from '
      'the loaded takeout', () async {
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([
      _pending('A'),
      _pending('not-in-takeout'),
    ]);

    c.listen(queueChannelAssignmentProvider, (_, _) {});
    await c.read(takeoutProvider.future);
    await pumpEventQueue();

    final channels = {
      for (final i in await container().read(deletionQueueProvider.future))
        i.itemId: i.authorChannelId,
    };
    expect(channels, {'A': 'UCme', 'not-in-takeout': null});
  });

  group('saved takeouts', () {
    final other = TakeoutData(
      comments: [
        _comment('X', '2026-02-01T00:00:00Z').copyWith(channelId: 'UCother'),
      ],
      liveChats: const [],
      subscriptionsByChannelId: const {},
      latestExportAt: DateTime.utc(2026, 3),
    );
    late _SignIns signIns;

    ProviderContainer withSignIns() {
      signIns = _SignIns({'UCme', 'UCother'});
      final c = ProviderContainer(
        overrides: [
          takeoutRepositoryProvider.overrideWithValue(repository),
          savedSignInsProvider.overrideWith(() => signIns),
        ],
      );
      addTearDown(c.dispose);
      c.listen(takeoutProvider, (_, _) {});
      return c;
    }

    setUp(() => repository.accounts['UCother'] = encodeTakeoutCsvs(other));

    test('are listed with their channels, newest export first', () async {
      final c = withSignIns();
      await c.read(takeoutProvider.future);

      final saved = await c.read(savedTakeoutsProvider.future);

      expect(saved.map((s) => s.id), ['UCother', 'UCme']);
      expect(saved.first.channelIds, {'UCother'});
      expect(saved.first.main.commentCount, 1);
      expect(saved.last.main.commentCount, 3);
    });

    test("removing one deletes its data, queued items and its channels' "
        'sign-ins', () async {
      final c = withSignIns();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        _pending('X').copyWith(authorChannelId: 'UCother'),
        _pending('A').copyWith(authorChannelId: 'UCme'),
      ]);
      await c.read(takeoutProvider.future);
      final saved = c.read(takeoutRemoverProvider.notifier);

      final removal = await saved.planRemoval('UCother');
      expect(removal.orphanedChannelIds, {'UCother'});
      expect(removal.queuedCount, 1);
      expect(removal.signInIds, {'UCother'});
      await saved.removeTakeout(removal);

      expect(repository.accounts.keys, ['UCme']);
      expect(await queuedItemIds(c), ['A']);
      expect(signIns.removed, {'UCother'});
      expect((await c.read(savedTakeoutsProvider.future)).map((s) => s.id), [
        'UCme',
      ]);
    });

    test('removing the viewed one switches to another', () async {
      final c = withSignIns();
      await c.read(takeoutProvider.future);
      final saved = c.read(takeoutRemoverProvider.notifier);

      await saved.removeTakeout(await saved.planRemoval('UCme'));

      expect(
        (await c.read(takeoutSelectionProvider.future))?.takeoutId,
        'UCother',
      );
      expect((await c.read(takeoutProvider.future))?.id, 'UCother');
    });

    test('removing the last one shows none', () async {
      repository.accounts.remove('UCother');
      final c = withSignIns();
      await c.read(takeoutProvider.future);
      final saved = c.read(takeoutRemoverProvider.notifier);

      await saved.removeTakeout(await saved.planRemoval('UCme'));

      expect(await c.read(takeoutSelectionProvider.future), isNull);
      expect(await c.read(takeoutProvider.future), isNull);
    });

    test('an import sharing a channel with another saved takeout goes into '
        'it', () async {
      repository.accounts['UCmulti'] = encodeTakeoutCsvs(
        other.copyWith(
          comments: [
            _comment(
              'M',
              '2026-01-01T00:00:00Z',
            ).copyWith(channelId: 'UCmulti'),
            _comment('N', '2026-01-02T00:00:00Z').copyWith(channelId: 'UCalt'),
          ],
        ),
      );
      final c = withSignIns();
      await c.read(takeoutProvider.future);

      final (:plan, csvFiles: _) = await c
          .read(takeoutImporterProvider.notifier)
          .prepareImport(_newerTakeout(channel: 'UCalt'), merge: false);

      expect(plan.accountId, 'UCmulti');
    });

    test('an import prepared before switching takeouts is refused', () async {
      final c = withSignIns();
      await c.read(takeoutProvider.future);
      final notifier = c.read(takeoutImporterProvider.notifier);
      final prepared = await notifier.prepareImport(
        _newerTakeout(),
        merge: true,
      );
      final savedFiles = repository.accounts['UCme'];

      await c.read(takeoutSelectionProvider.notifier).select('UCother');

      await expectLater(
        notifier.commitImport(prepared),
        throwsA(isA<TakeoutImportException>()),
      );
      expect(repository.accounts['UCme'], same(savedFiles));
    });
  });

  group('switching takeouts', () {
    final other = TakeoutData(
      comments: [
        _comment('X', '2026-01-01T00:00:00Z').copyWith(channelId: 'UCother'),
      ],
      liveChats: const [],
      subscriptionsByChannelId: const {},
    );

    setUp(() => repository.accounts['UCother'] = encodeTakeoutCsvs(other));

    Future<List<String>> viewedCommentIds(ProviderContainer c) async {
      await c.read(takeoutProvider.future);
      return [
        for (final comment
            in c.read(viewedTakeoutProvider).requireValue!.comments)
          comment.commentId,
      ];
    }

    test('loads the other takeout', () async {
      final c = container();
      c.listen(viewedTakeoutProvider, (_, _) {});
      expect(await viewedCommentIds(c), unorderedEquals(['A', 'B', 'C']));

      await c.read(takeoutSelectionProvider.notifier).select('UCother');

      expect(await viewedCommentIds(c), ['X']);
    });

    test('never shows the old takeout while the new one loads', () async {
      final c = container();
      c.listen(viewedTakeoutProvider, (_, _) {});
      await viewedCommentIds(c);

      await c.read(takeoutSelectionProvider.notifier).select('UCother');

      final viewed = c.read(viewedTakeoutProvider);
      expect(viewed.isLoading, isTrue);
      expect(viewed.value, isNull);
    });

    test('ends on the last of several quick switches', () async {
      final c = container();
      c.listen(viewedTakeoutProvider, (_, _) {});
      await viewedCommentIds(c);
      final selection = c.read(takeoutSelectionProvider.notifier);

      final away = selection.select('UCother');
      await selection.select('UCme');
      await away;

      expect((await c.read(takeoutProvider.future))!.id, 'UCme');
      expect(await viewedCommentIds(c), unorderedEquals(['A', 'B', 'C']));
    });

    test('an import into another takeout shows it', () async {
      final c = container();
      await c.read(takeoutProvider.future);
      final notifier = c.read(takeoutImporterProvider.notifier);
      final prepared = await notifier.prepareImport(
        _newerTakeout(channel: 'UCnew'),
        merge: false,
      );

      await notifier.commitImport(prepared);

      expect((await c.read(takeoutProvider.future))!.id, 'UCnew');
      expect(await commentIds(c), unorderedEquals(['A', 'C', 'D']));
      expect(
        (await c.read(takeoutSelectionProvider.future))?.takeoutId,
        'UCnew',
      );
    });

    test("shows only the viewed channel's items", () async {
      repository.accounts['UCme'] = encodeTakeoutCsvs(
        _savedAbc.copyWith(
          comments: [
            ..._savedAbc.comments,
            _comment(
              'Alt',
              '2026-01-04T00:00:00Z',
            ).copyWith(channelId: 'UCalt'),
          ],
          ownChannels: const {
            'UCme': OwnChannel(channelId: 'UCme', title: 'Me'),
            'UCalt': OwnChannel(channelId: 'UCalt', title: 'Alt'),
          },
        ),
      );
      final c = container();
      c.listen(viewedTakeoutProvider, (_, _) {});

      expect(await viewedCommentIds(c), unorderedEquals(['A', 'B', 'C']));
      expect(c.read(viewedChannelIdProvider), 'UCme');
      expect(c.read(takeoutChannelsProvider).map((ch) => ch.channelId), [
        'UCme',
        'UCalt',
      ]);

      await c.read(takeoutSelectionProvider.notifier).selectChannel('UCalt');

      expect(c.read(viewedChannelIdProvider), 'UCalt');
      expect(await viewedCommentIds(c), ['Alt']);
    });
  });
}

/// Saved sign-ins for [channelIds], recording which get removed.
class _SignIns extends SavedSignIns {
  final Set<String> channelIds;
  final removed = <String>{};

  _SignIns(this.channelIds);

  @override
  Future<Map<String, SignInProfile>> build() async => {
    for (final id in channelIds) id: SignInProfile(channelId: id),
  };

  @override
  Future<void> removeAll(Set<String> channelIds) async =>
      removed.addAll(channelIds);
}

class _Idle extends ChannelThumbnailFetcher {
  @override
  void build() {}
}

class _IdleEmoji extends EmojiNameResolver {
  @override
  void build() {}
}
