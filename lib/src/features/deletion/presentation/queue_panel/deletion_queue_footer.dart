import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/presentation/quota_status_bar.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import '../../application/deletion_processing.dart';
import '../../application/deletion_queue_counts.dart';
import '../../application/deletion_queue_notifier.dart';
import '../deletion_method_picker.dart';

/// The queue's controls: delete or pause, retry failed, clear done, and
/// the API quota when signed in.
class DeletionQueueFooter extends ConsumerWidget {
  final DeletionQueueCounts counts;

  const DeletionQueueFooter({super.key, required this.counts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isAuthenticatedProvider);
    final processing = ref.watch(deletionProcessingProvider);
    final notifier = ref.read(deletionQueueProvider.notifier);
    final channelId = ref.watch(viewedChannelIdProvider);
    final running = processing != DeletionProcessingState.idle;

    final buttons = [
      if (running)
        FilledButton.tonalIcon(
          onPressed: processing == DeletionProcessingState.running
              ? ref.read(deletionProcessingProvider.notifier).pauseProcessing
              : null,
          icon: const Icon(Icons.pause),
          label: Text(
            processing == DeletionProcessingState.running
                ? 'Pause'
                : 'Pausing…',
            textAlign: TextAlign.center,
          ),
        )
      else if (counts.waiting > 0)
        FilledButton.icon(
          onPressed: () => deleteQueuedItems(context, ref),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(
            Intl.plural(
              counts.waiting,
              one: 'Delete 1…',
              other: 'Delete ${counts.waiting}…',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      if (counts.failed > 0 && !running)
        TextButton.icon(
          onPressed: channelId == null
              ? null
              : () => notifier.retryFailed(channelId: channelId),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry failed', textAlign: TextAlign.center),
        ),
      if (counts.done > 0)
        TextButton.icon(
          onPressed: channelId == null
              ? null
              : () => notifier.clearCompleted(channelId: channelId),
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear done', textAlign: TextAlign.center),
        ),
    ];
    if (!signedIn && buttons.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (signedIn)
                const QuotaStatusBar(compact: true, padding: EdgeInsets.zero),
              if (signedIn && buttons.isNotEmpty) const SizedBox(height: 12),
              if (buttons.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: buttons),
            ],
          ),
        ),
      ),
    );
  }
}
