import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/add_account_import.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_importer.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_request.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';

final _picked = [PickedZip.bytes('takeout-001.zip', Uint8List(1))];

const _plan = TakeoutImportPlan(
  accountId: 'UCnew',
  mergedData: TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
  ),
  goneCommentIds: {},
  goneLiveChatIds: {},
  newlyDeletedCommentIds: {},
  newlyDeletedLiveChatIds: {},
  newCommentIds: {},
  newLiveChatIds: {},
);

/// A plan with something to look over even as a first import.
const _planWithDeleted = TakeoutImportPlan(
  accountId: 'UCnew',
  mergedData: TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
  ),
  goneCommentIds: {'gone'},
  goneLiveChatIds: {},
  newlyDeletedCommentIds: {'gone'},
  newlyDeletedLiveChatIds: {},
  newCommentIds: {},
  newLiveChatIds: {},
);

const _savedSummary = TakeoutSummary(
  id: 'UCme',
  channels: [
    TakeoutChannel(
      channelId: 'UCme',
      isMain: true,
      listed: true,
      commentCount: 1,
      liveChatCount: 0,
    ),
  ],
  countsKnown: true,
);

class _SavedTakeouts extends SavedTakeouts {
  final List<TakeoutSummary> summaries;

  _SavedTakeouts(this.summaries);

  @override
  Future<List<TakeoutSummary>> build() async => summaries;
}

class _Picker implements ZipPickerRepository {
  final List<PickedZip>? result;
  final Object? error;

  _Picker(this.result, {this.error});

  @override
  Future<List<PickedZip>?> pickZips() async =>
      error != null ? throw error! : result;
}

class _Takeout extends TakeoutImporter {
  final Object? importError;
  final Set<String> saved;
  final Completer<void>? commitGate;
  final TakeoutImportPlan plan;
  Object? mergeError;
  final prepared = <bool>[];
  final committed = <TakeoutImportPlan>[];

  _Takeout({
    this.importError,
    this.saved = const {},
    this.commitGate,
    this.plan = _plan,
  });

  @override
  void build() {}

  @override
  Future<PreparedImport> prepareImport(
    List<PickedZip> zips, {
    required bool merge,
  }) async {
    prepared.add(merge);
    if (importError case final error?) throw error;
    if (mergeError case final error? when merge) throw error;
    return (plan: plan, csvFiles: const <String, Uint8List>{});
  }

  @override
  Future<void> commitImport(PreparedImport prepared) async {
    final plan = prepared.plan;
    await commitGate?.future;
    committed.add(plan);
  }

  @override
  Future<bool> hasSavedData(String accountId) async =>
      saved.contains(accountId);
}

class _NoTakeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => null;
}

class _Selection extends TakeoutSelectionNotifier {
  final String viewing;
  final selected = <String>[];

  _Selection(this.viewing);

  @override
  Future<TakeoutSelection?> build() async =>
      TakeoutSelection(takeoutId: viewing);

  @override
  Future<void> select(String takeoutId, {String? channelId}) async {
    selected.add(takeoutId);
    state = AsyncData(TakeoutSelection(takeoutId: takeoutId));
  }
}

void main() {
  late _Takeout takeout;
  late _Selection selection;

  ProviderContainer container({
    List<PickedZip>? picked,
    Object? pickError,
    Object? importError,
    Set<String> saved = const {},
    Completer<void>? commitGate,
    String viewing = 'UCme',
    List<TakeoutSummary> savedTakeouts = const [_savedSummary],
    TakeoutImportPlan plan = _plan,
  }) {
    takeout = _Takeout(
      importError: importError,
      saved: saved,
      commitGate: commitGate,
      plan: plan,
    );
    selection = _Selection(viewing);
    final c = ProviderContainer(
      overrides: [
        zipPickerRepositoryProvider.overrideWithValue(
          _Picker(picked, error: pickError),
        ),
        takeoutImporterProvider.overrideWith(() => takeout),
        takeoutProvider.overrideWith(_NoTakeout.new),
        takeoutSelectionProvider.overrideWith(() => selection),
        savedTakeoutsProvider.overrideWith(() => _SavedTakeouts(savedTakeouts)),
      ],
    );
    addTearDown(c.dispose);
    c.listen(addAccountImportProvider, (_, _) {});
    return c;
  }

  test(
    'reads the picked takeout without merging, then asks to review it',
    () async {
      final c = container(picked: _picked);

      await c.read(addAccountImportProvider.notifier).start();

      expect(takeout.prepared, [false]);
      final state = c.read(addAccountImportProvider);
      expect(state, isA<AddAccountReview>());
      expect((state as AddAccountReview).plan, same(_plan));
      expect(takeout.committed, isEmpty);
    },
  );

  test('picking nothing changes nothing', () async {
    final c = container();

    expect(await c.read(addAccountImportProvider.notifier).start(), isFalse);

    expect(takeout.prepared, isEmpty);
    expect(c.read(addAccountImportProvider), isA<AddAccountIdle>());
  });

  test('the first takeout is saved straight away when there is nothing to look '
      'over', () async {
    final c = container(picked: _picked, savedTakeouts: const []);

    expect(await c.read(addAccountImportProvider.notifier).start(), isTrue);

    expect(takeout.committed, [same(_plan)]);
    expect(c.read(addAccountImportProvider), isA<AddAccountIdle>());
  });

  test('the first takeout is reviewed when it found items deleted', () async {
    final c = container(
      picked: _picked,
      savedTakeouts: const [],
      plan: _planWithDeleted,
    );

    expect(await c.read(addAccountImportProvider.notifier).start(), isFalse);

    expect(c.read(addAccountImportProvider), isA<AddAccountReview>());
    expect(takeout.committed, isEmpty);
  });

  test('a takeout from an account already saved shows that account, then '
      'reviews the merge', () async {
    final c = container(picked: _picked, saved: {'UCnew'});
    final add = c.read(addAccountImportProvider.notifier);

    expect(await add.start(), isFalse);

    expect(selection.selected, ['UCnew']);
    expect(takeout.prepared, [false, true]);
    expect(c.read(addAccountImportProvider), isA<AddAccountMergeReview>());
    expect(takeout.committed, isEmpty);

    expect(await add.confirm(), isTrue);
    expect(takeout.committed, [same(_plan)]);
    expect(c.read(addAccountImportProvider), isA<AddAccountIdle>());
  });

  test(
    "a merge review asks for its new items' videos until it's done",
    () async {
      Comment comment(String id, String videoId) => Comment(
        commentId: id,
        channelId: 'UCnew',
        createdAt: DateTime.utc(2026),
        price: 0,
        videoId: videoId,
        rawCommentText: '',
        displayText: '',
      );
      final plan = TakeoutImportPlan(
        accountId: 'UCnew',
        mergedData: TakeoutData(
          comments: [comment('new', 'vNew'), comment('old', 'vOld')],
          liveChats: const [],
          subscriptionsByChannelId: const {},
        ),
        goneCommentIds: const {},
        goneLiveChatIds: const {},
        newlyDeletedCommentIds: const {},
        newlyDeletedLiveChatIds: const {},
        newCommentIds: const {'new'},
        newLiveChatIds: const {},
      );
      final c = container(picked: _picked, saved: {'UCnew'}, plan: plan);
      final add = c.read(addAccountImportProvider.notifier);

      await add.start();
      expect(c.read(extraVideoIdsProvider), {'vNew'});

      add.dismiss();
      expect(c.read(extraVideoIdsProvider), isEmpty);
    },
  );

  test('merging into the account shown stays on it', () async {
    final c = container(picked: _picked, saved: {'UCnew'}, viewing: 'UCnew');

    await c.read(addAccountImportProvider.notifier).start();

    expect(selection.selected, isEmpty);
    expect(c.read(addAccountImportProvider), isA<AddAccountMergeReview>());
  });

  test('a merge that fails to read says why', () async {
    final c = container(picked: _picked, saved: {'UCnew'});
    takeout.mergeError = const TakeoutImportException('Not a takeout.');

    await c.read(addAccountImportProvider.notifier).start();

    expect(c.read(addAccountImportProvider), isA<AddAccountFailed>());
  });

  test("a picked file that can't be read says why", () async {
    const error = TakeoutImportException('Couldn\'t read "takeout-001.zip".');
    final c = container(pickError: error);

    await c.read(addAccountImportProvider.notifier).start();

    final state = c.read(addAccountImportProvider);
    expect(state, isA<AddAccountFailed>());
    expect((state as AddAccountFailed).error, same(error));
    expect(takeout.prepared, isEmpty);
  });

  test('a takeout that fails to read says why', () async {
    const error = TakeoutImportException('Not a takeout.');
    final c = container(picked: _picked, importError: error);

    await c.read(addAccountImportProvider.notifier).start();

    final state = c.read(addAccountImportProvider);
    expect(state, isA<AddAccountFailed>());
    expect((state as AddAccountFailed).error, same(error));
  });

  test('confirming saves it, saying so until done', () async {
    final gate = Completer<void>();
    final c = container(picked: _picked, commitGate: gate);
    final add = c.read(addAccountImportProvider.notifier);
    await add.start();

    final saving = add.confirm();
    expect(c.read(addAccountImportProvider), isA<AddAccountWorking>());
    gate.complete();
    expect(await saving, isTrue);

    expect(takeout.committed, [same(_plan)]);
    expect(c.read(addAccountImportProvider), isA<AddAccountIdle>());
  });

  test('dismissing goes back to the start', () async {
    final c = container(picked: _picked);
    final add = c.read(addAccountImportProvider.notifier);
    await add.start();

    add.dismiss();

    expect(c.read(addAccountImportProvider), isA<AddAccountIdle>());
    expect(takeout.committed, isEmpty);
  });
}
