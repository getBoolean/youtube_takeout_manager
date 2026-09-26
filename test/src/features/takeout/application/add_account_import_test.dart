import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/add_account_import.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/zip_picker_repository.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_import_plan.dart';

final _picked = FilePickerResult([
  PlatformFile(name: 'takeout-001.zip', size: 1, bytes: Uint8List(1)),
]);

const _plan = TakeoutImportPlan(
  accountId: 'UCnew',
  mergedData: TakeoutData(
    comments: [],
    liveChats: [],
    subscriptionsByChannelId: {},
  ),
  csvFiles: {},
  goneCommentIds: {},
  goneLiveChatIds: {},
  newlyDeletedCommentCount: 0,
  newlyDeletedLiveChatCount: 0,
  newCommentCount: 0,
  newLiveChatCount: 0,
);

class _Picker implements ZipPickerRepository {
  final FilePickerResult? result;

  _Picker(this.result);

  @override
  Future<FilePickerResult?> pickZips() async => result;
}

class _Takeout extends TakeoutNotifier {
  final Object? importError;
  final Set<String> saved;
  final Completer<void>? commitGate;
  Object? failNext;
  final prepared = <bool>[];
  final committed = <TakeoutImportPlan>[];

  _Takeout({this.importError, this.saved = const {}, this.commitGate});

  @override
  Future<LoadedTakeout?> build() async => null;

  @override
  Future<TakeoutImportPlan> prepareImport(
    FilePickerResult picked, {
    required bool merge,
  }) async {
    prepared.add(merge);
    if (importError case final error?) throw error;
    if (failNext case final error?) throw error;
    return _plan;
  }

  @override
  Future<void> commitImport(TakeoutImportPlan plan) async {
    await commitGate?.future;
    committed.add(plan);
  }

  @override
  Future<bool> hasSavedData(String accountId) async =>
      saved.contains(accountId);
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
    FilePickerResult? picked,
    Object? importError,
    Set<String> saved = const {},
    Completer<void>? commitGate,
    String viewing = 'UCme',
  }) {
    takeout = _Takeout(
      importError: importError,
      saved: saved,
      commitGate: commitGate,
    );
    selection = _Selection(viewing);
    final c = ProviderContainer(
      overrides: [
        zipPickerRepositoryProvider.overrideWithValue(_Picker(picked)),
        takeoutProvider.overrideWith(() => takeout),
        takeoutSelectionProvider.overrideWith(() => selection),
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

    await c.read(addAccountImportProvider.notifier).start();

    expect(takeout.prepared, isEmpty);
    expect(c.read(addAccountImportProvider), isA<AddAccountIdle>());
  });

  test(
    'a takeout from an account already saved asks whether to merge',
    () async {
      final c = container(picked: _picked, saved: {'UCnew'});

      await c.read(addAccountImportProvider.notifier).start();

      final state = c.read(addAccountImportProvider);
      expect(state, isA<AddAccountAlreadySaved>());
      expect((state as AddAccountAlreadySaved).takeoutId, 'UCnew');
      expect(takeout.committed, isEmpty);
    },
  );

  test('merging shows that account, then reviews the merge', () async {
    final c = container(picked: _picked, saved: {'UCnew'});
    final add = c.read(addAccountImportProvider.notifier);
    await add.start();

    await add.merge();

    expect(selection.selected, ['UCnew']);
    expect(takeout.prepared, [false, true]);
    final state = c.read(addAccountImportProvider);
    expect(state, isA<AddAccountMergeReview>());
    expect(takeout.committed, isEmpty);

    await add.confirm();
    expect(takeout.committed, [same(_plan)]);
    expect(c.read(addAccountImportProvider), isA<AddAccountIdle>());
  });

  test('merging into the account shown stays on it', () async {
    final c = container(picked: _picked, saved: {'UCnew'}, viewing: 'UCnew');
    final add = c.read(addAccountImportProvider.notifier);
    await add.start();

    await add.merge();

    expect(selection.selected, isEmpty);
    expect(c.read(addAccountImportProvider), isA<AddAccountMergeReview>());
  });

  test('a merge that fails to read says why', () async {
    final c = container(picked: _picked, saved: {'UCnew'});
    final add = c.read(addAccountImportProvider.notifier);
    await add.start();
    takeout.failNext = const TakeoutImportException('Not a takeout.');

    await add.merge();

    expect(c.read(addAccountImportProvider), isA<AddAccountFailed>());
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
    await saving;

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
