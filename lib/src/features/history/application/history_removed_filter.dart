import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_removed_filter.g.dart';

/// Whether the history screen shows only entries a newer takeout no longer
/// had, removed from YouTube's history.
@riverpod
class HistoryRemovedFilter extends _$HistoryRemovedFilter {
  @override
  bool build() => false;

  void set(bool removedOnly) => state = removedOnly;
}
