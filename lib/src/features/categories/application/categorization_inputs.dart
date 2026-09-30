import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/history/application/history_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_shown.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';

part 'categorization_inputs.g.dart';

/// The channels to categorize come from these: the watched history and the
/// subscriptions.
typedef CategorizationInputs = ({
  LoadedHistory loaded,
  SubscriptionMatch subscriptions,
});

/// What categorizing works from, once the history screen has been opened;
/// null before, so history isn't loaded for it at startup.
@riverpod
CategorizationInputs? categorizationInputs(Ref ref) {
  if (!ref.watch(historyShownProvider)) return null;
  final loaded = ref.watch(takeoutHistoryProvider).value;
  if (loaded == null) return null;
  return (
    loaded: loaded,
    subscriptions: ref.watch(historySubscriptionMatchProvider),
  );
}
