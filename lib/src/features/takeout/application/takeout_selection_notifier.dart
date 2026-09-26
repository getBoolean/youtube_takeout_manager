import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/takeout_account_repository.dart';
import '../data/takeout_import_planner.dart';
import '../data/takeout_import_service.dart';
import '../data/takeout_repository.dart';
import '../domain/channel_id.dart';
import '../domain/takeout_import_plan.dart';
import '../domain/takeout_selection.dart';

part 'takeout_selection_notifier.g.dart';

/// The saved takeout being shown and the channel chosen in it. Each change
/// shows at once and is saved in the order made, so what's saved always
/// matches the last change.
// A failure is deterministic (legacy data no channel wrote), and retrying
// would parse that data again each time.
@Riverpod(keepAlive: true, retry: _noRetry)
class TakeoutSelectionNotifier extends _$TakeoutSelectionNotifier {
  Future<void> _saving = Future.value();

  /// Counts [select] calls, so one that finished looking up the takeout's
  /// remembered channel after a newer call doesn't overwrite it.
  var _generation = 0;

  TakeoutAccountRepository get _repository =>
      ref.read(takeoutAccountRepositoryProvider);

  @override
  Future<TakeoutSelection?> build() async {
    final repository = ref.watch(takeoutAccountRepositoryProvider);
    final takeoutId =
        await repository.loadActiveAccountId() ??
        await _moveLegacyCsvs(ref.watch(takeoutRepositoryProvider));
    if (takeoutId == null) return null;
    return TakeoutSelection(
      takeoutId: takeoutId,
      channelId: await repository.loadViewedChannelId(takeoutId),
    );
  }

  /// Moves CSVs saved before takeouts were kept per account into the folder
  /// of the channel that wrote most of them, and returns that channel. Throws,
  /// keeping them, when no channel wrote them, rather than showing data tied
  /// to no channel.
  Future<String?> _moveLegacyCsvs(TakeoutRepository takeouts) async {
    final legacyCsvs = await takeouts.loadLegacyCsvs();
    if (legacyCsvs == null) return null;

    final data = await compute(parseCsvFiles, legacyCsvs);
    final accountId = mostCommonAuthorChannelId(data);
    if (accountId == null || !isChannelId(accountId)) {
      throw TakeoutImportException(
        "Your saved data couldn't be matched to a YouTube channel "
        '(${accountId ?? 'no channel ID'}). Import your takeout again.',
      );
    }
    await takeouts.saveCsvs(accountId, legacyCsvs);
    await _repository.saveActiveAccountId(accountId);
    await takeouts.clearLegacyCsvs();
    return accountId;
  }

  /// Shows [takeoutId], on [channelId] or else the channel last viewed in it.
  Future<void> select(String takeoutId, {String? channelId}) async {
    final generation = ++_generation;
    final channel =
        channelId ?? await _repository.loadViewedChannelId(takeoutId);
    if (generation != _generation) return _saving;
    state = AsyncData(
      TakeoutSelection(takeoutId: takeoutId, channelId: channel),
    );
    return _save((repository) async {
      await repository.saveActiveAccountId(takeoutId);
      if (channelId != null) {
        await repository.saveViewedChannelId(takeoutId, channelId);
      }
    });
  }

  /// Shows [channelId] in the current takeout.
  Future<void> selectChannel(String channelId) async {
    final current = await future;
    if (current == null) return;
    _generation++;
    state = AsyncData(current.copyWith(channelId: channelId));
    return _save(
      (repository) =>
          repository.saveViewedChannelId(current.takeoutId, channelId),
    );
  }

  /// Shows no takeout.
  Future<void> clear() async {
    _generation++;
    state = const AsyncData(null);
    return _save((repository) => repository.clearActiveAccountId());
  }

  Future<void> _save(
    Future<void> Function(TakeoutAccountRepository repository) change,
  ) {
    final repository = _repository;
    return _saving = _saving.then((_) => change(repository));
  }
}

Duration? _noRetry(int retryCount, Object error) => null;
