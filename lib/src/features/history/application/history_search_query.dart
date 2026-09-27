import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_search_query.g.dart';

/// Search text on the history screen, shared by its tabs.
@riverpod
class HistorySearchQuery extends _$HistorySearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}
