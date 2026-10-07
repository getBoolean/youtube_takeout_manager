import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

part 'history_grouping.g.dart';

/// How the history screen groups the watched videos.
enum HistoryGrouping { day, month, channel }

const _key = 'history.grouping';

/// How the history screen groups the watched videos now: the last grouping
/// picked, kept across restarts, else by channel.
@Riverpod(keepAlive: true)
class HistoryGroupingNotifier extends _$HistoryGroupingNotifier {
  @override
  Future<HistoryGrouping> build() async {
    final saved = await ref.watch(kvStorageServiceProvider).getString(_key);
    // A grouping since removed, or anything unreadable, means by channel.
    return HistoryGrouping.values.asNameMap()[saved] ?? HistoryGrouping.channel;
  }

  /// Groups by [grouping] at once, and keeps it.
  Future<void> set(HistoryGrouping grouping) async {
    state = AsyncData(grouping);
    await ref.read(kvStorageServiceProvider).setString(_key, grouping.name);
  }
}
