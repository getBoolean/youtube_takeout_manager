import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/takeout_account_repository.dart';
import '../domain/takeout_selection.dart';

part 'takeout_selection_notifier.g.dart';

/// The saved takeout being shown and the channel chosen in it. Each change
/// shows at once and is saved in the order made, so what's saved always
/// matches the last change.
// A failure shows at once: storage that can't read the selection won't on a
// retry either.
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
    final takeoutId = await repository.loadActiveAccountId();
    if (takeoutId == null) return null;
    return TakeoutSelection(
      takeoutId: takeoutId,
      channelId: await repository.loadViewedChannelId(takeoutId),
    );
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
