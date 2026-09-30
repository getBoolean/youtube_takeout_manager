import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_grouping.g.dart';

/// How the history screen groups the watched videos.
enum HistoryGrouping { day, month, channel, category }

/// How the history screen groups the watched videos now.
@riverpod
class HistoryGroupingNotifier extends _$HistoryGroupingNotifier {
  @override
  HistoryGrouping build() => HistoryGrouping.day;

  void set(HistoryGrouping grouping) => state = grouping;
}
