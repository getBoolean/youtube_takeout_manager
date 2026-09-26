import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/signed_in_channel_provider.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/own_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';

class _MemoryTakeoutRepository implements TakeoutRepository {
  final accounts = <String, Map<String, Uint8List>>{};
  Map<String, Uint8List>? legacy;
  bool failSaves = false;
  var loads = 0;

  @override
  Future<void> saveCsvs(
    String accountId,
    Map<String, Uint8List> csvFiles,
  ) async {
    if (failSaves) throw const FileSystemException('disk full');
    accounts[accountId] = {...csvFiles};
  }

  @override
  Future<Map<String, Uint8List>?> loadCsvs(String accountId) async {
    loads++;
    return accounts[accountId];
  }

  @override
  Future<void> clearCsvs(String accountId) async => accounts.remove(accountId);

  @override
  Future<Map<String, Uint8List>?> loadLegacyCsvs() async => legacy;

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
FilePickerResult _newerTakeout({String channel = 'UCme'}) {
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
  final bytes = ZipEncoder().encodeBytes(archive);
  return FilePickerResult([
    PlatformFile(
      name: 'takeout-20260301T000000Z-001.zip',
      size: bytes.length,
      bytes: bytes,
    ),
  ]);
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

  ProviderContainer container({Future<String?> Function()? signedInChannelId}) {
    final container = ProviderContainer(
      overrides: [
        takeoutRepositoryProvider.overrideWithValue(repository),
        if (signedInChannelId != null)
          signedInChannelIdProvider.overrideWith((_) => signedInChannelId()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<List<String>> commentIds(ProviderContainer c) async => [
    for (final comment in (await c.read(takeoutProvider.future))!.data.comments)
      comment.commentId,
  ];

  Future<List<String>> queuedItemIds(ProviderContainer c) async => [
    for (final i in await c.read(deletionQueueProvider.future)) i.itemId,
  ];

  test(
    'adding a newer takeout merges it and marks missing items deleted',
    () async {
      final c = container();
      await c.read(deletionQueueRepositoryProvider).saveQueue([
        _pending('B'),
        _pending('C'),
      ]);
      final notifier = c.read(takeoutProvider.notifier);

      final plan = await notifier.prepareImport(_newerTakeout(), merge: true);
      await notifier.commitImport(plan);

      expect(await commentIds(c), ['D', 'C', 'B', 'A']);
      expect(await c.read(deletedCommentIdsProvider.future), {'B'});
      expect(await queuedItemIds(c), ['C']);

      final restarted = container();
      expect(await commentIds(restarted), ['D', 'C', 'B', 'A']);
      expect(
        (await restarted.read(takeoutProvider.future))!.data.latestExportAt,
        DateTime.utc(2026, 3),
      );
      expect(await restarted.read(deletedCommentIdsProvider.future), {'B'});
    },
  );

  test('items already deleted are not counted as newly deleted', () async {
    final c = container();
    await c.read(deletedCommentIdsProvider.notifier).markDeleted({'B'});

    final plan = await c
        .read(takeoutProvider.notifier)
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
          .read(takeoutProvider.notifier)
          .prepareImport(_newerTakeout(channel: 'UCother'), merge: true),
      throwsA(isA<TakeoutAccountMismatchException>()),
    );

    expect(repository.accounts, {'UCme': same(savedFiles)});
    expect(await commentIds(c), ['A', 'B', 'C']);
    expect(await c.read(deletedCommentIdsProvider.future), isEmpty);
    expect(await queuedItemIds(c), ['B']);
  });

  test('a picked file that could not be read is rejected', () async {
    final c = container();

    await expectLater(
      c
          .read(takeoutProvider.notifier)
          .prepareImport(
            FilePickerResult([
              PlatformFile(name: 'takeout-20260301T000000Z-001.zip', size: 1),
            ]),
            merge: true,
          ),
      throwsA(isA<TakeoutImportException>()),
    );
  });
  test("replacing with another account's takeout saves it separately and "
      'switches to it', () async {
    final c = container();
    final savedFiles = repository.accounts['UCme'];
    final notifier = c.read(takeoutProvider.notifier);

    final plan = await notifier.prepareImport(
      _newerTakeout(channel: 'UCother'),
      merge: false,
    );
    await notifier.commitImport(plan);

    expect(plan.differentAccount?.foundChannelIds, {'UCother'});
    expect(await commentIds(c), ['D', 'C', 'A']);
    expect(repository.accounts['UCme'], same(savedFiles));
    expect(repository.accounts.keys, unorderedEquals(['UCme', 'UCother']));
    expect(await commentIds(container()), ['D', 'C', 'A']);
  });

  test(
    'data saved before per-account storage moves into its account',
    () async {
      SharedPreferences.setMockInitialValues({});
      repository.accounts.clear();
      final legacy = encodeTakeoutCsvs(_savedAbc);
      repository.legacy = legacy;

      expect(await commentIds(container()), ['A', 'B', 'C']);
      expect(repository.accounts, {'UCme': legacy});
      expect(repository.legacy, isNull);
      expect(await commentIds(container()), ['A', 'B', 'C']);
    },
  );

  test(
    'a takeout from another channel than the signed-in one is rejected',
    () async {
      final c = container(signedInChannelId: () async => 'UCsignedIn');

      await expectLater(
        c
            .read(takeoutProvider.notifier)
            .prepareImport(_newerTakeout(), merge: true),
        throwsA(
          isA<TakeoutAccountMismatchException>().having(
            (e) => e.expectedChannelIds,
            'expected',
            {'UCsignedIn'},
          ),
        ),
      );
    },
  );

  test(
    "an import is blocked when the signed-in channel can't be looked up",
    () async {
      final c = container(
        signedInChannelId: () async => throw Exception('offline'),
      );

      await expectLater(
        c
            .read(takeoutProvider.notifier)
            .prepareImport(_newerTakeout(), merge: true),
        throwsA(isA<TakeoutImportException>()),
      );
    },
  );
  test(
    'a failed signed-in channel lookup is retried on the next import',
    () async {
      var lookups = 0;
      final c = container(
        signedInChannelId: () async {
          if (++lookups == 1) throw Exception('offline');
          return 'UCme';
        },
      );
      final notifier = c.read(takeoutProvider.notifier);

      await expectLater(
        notifier.prepareImport(_newerTakeout(), merge: true),
        throwsA(isA<TakeoutImportException>()),
      );
      final plan = await notifier.prepareImport(_newerTakeout(), merge: true);

      expect(plan.accountId, 'UCme');
    },
  );
  test('items found gone stay marked even if saving fails', () async {
    final c = container();
    await c.read(deletionQueueRepositoryProvider).saveQueue([_pending('B')]);
    final savedFiles = repository.accounts['UCme'];
    final notifier = c.read(takeoutProvider.notifier);
    final plan = await notifier.prepareImport(_newerTakeout(), merge: true);

    repository.failSaves = true;
    await expectLater(
      notifier.commitImport(plan),
      throwsA(isA<FileSystemException>()),
    );

    expect(await c.read(deletedCommentIdsProvider.future), {'B'});
    expect(await queuedItemIds(c), isEmpty);
    expect(repository.accounts['UCme'], same(savedFiles));
  });

  test('data saved before per-account storage with an odd channel ID fails '
      'to load and stays where it is', () async {
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

    // Home then offers to import, rather than showing data tied to no
    // channel.
    await expectLater(
      container().read(takeoutSelectionProvider.future),
      throwsA(isA<TakeoutImportException>()),
    );
    expect(repository.accounts, isEmpty);
    expect(repository.legacy, same(legacy));
  });

  test('tells which accounts have saved data', () async {
    final notifier = container().read(takeoutProvider.notifier);

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

    await c.read(takeoutProvider.future);

    final channels = {
      for (final i in await container().read(deletionQueueProvider.future))
        i.itemId: i.authorChannelId,
    };
    expect(channels, {'A': 'UCme', 'not-in-takeout': null});
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
      expect(await viewedCommentIds(c), ['A', 'B', 'C']);

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
      expect(await viewedCommentIds(c), ['A', 'B', 'C']);
    });

    test(
      'an import into another takeout shows it without reloading it',
      () async {
        final c = container();
        await c.read(takeoutProvider.future);
        final notifier = c.read(takeoutProvider.notifier);
        final plan = await notifier.prepareImport(
          _newerTakeout(channel: 'UCnew'),
          merge: false,
        );
        final loads = repository.loads;

        await notifier.commitImport(plan);

        expect((await c.read(takeoutProvider.future))!.id, 'UCnew');
        expect(repository.loads, loads);
        expect(
          (await c.read(takeoutSelectionProvider.future))?.takeoutId,
          'UCnew',
        );
      },
    );

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

      expect(await viewedCommentIds(c), ['A', 'B', 'C']);
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
