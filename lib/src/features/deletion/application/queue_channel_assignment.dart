import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';

import 'deletion_queue_notifier.dart';

part 'queue_channel_assignment.g.dart';

/// Fills in the channel of queued deletions saved before it was. A service:
/// nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class QueueChannelAssigner extends _$QueueChannelAssigner {
  @override
  void build() {}

  /// Fills in the channel of queued deletions missing one, from [loaded]'s
  /// authors. Items that aren't in it keep waiting for theirs.
  Future<void> assign(LoadedTakeout loaded) async {
    final queue = ref.read(deletionQueueProvider.notifier);
    final items = await ref.read(deletionQueueProvider.future);
    final missing = {
      for (final i in items)
        if (i.authorChannelId == null) i.itemId,
    };
    if (missing.isEmpty) return;

    final data = loaded.data;
    String author(String channelId) =>
        data.authorOf(channelId, takeoutId: loaded.id);
    await queue.assignMissingChannels(
      commentAuthors: {
        for (final c in data.comments)
          if (missing.contains(c.commentId)) c.commentId: author(c.channelId),
      },
      liveChatAuthors: {
        for (final l in data.liveChats)
          if (missing.contains(l.liveChatId)) l.liveChatId: author(l.channelId),
      },
    );
  }
}

/// Fills in the channel of queued deletions saved before it was, each time
/// a takeout loads. An effect, started with the app.
@Riverpod(keepAlive: true)
void queueChannelAssignment(Ref ref) {
  ref.listen(takeoutProvider, (previous, next) {
    if (next case AsyncData(
      value: final loaded?,
    ) when !identical(loaded, previous?.value)) {
      unawaited(ref.read(queueChannelAssignerProvider.notifier).assign(loaded));
    }
  }, fireImmediately: true);
}
