import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../application/ai_tiers.dart';
import '../application/categorization_progress.dart';

/// While channels are categorized, how far along it is, as a slim bar with
/// a line saying so; it folds away when done. Above it, a notice about AI,
/// such as a key rejected, until dismissed.
class CategorizationBanner extends ConsumerWidget {
  const CategorizationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:running, :done, :total) = ref.watch(categorizationProgressProvider);
    final notice = ref.watch(aiTierStatusProvider.select((s) => s.notice));
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: NoticeBanner(
                title: notice,
                onDismiss: () =>
                    ref.read(aiTierStatusProvider.notifier).dismiss(),
              ),
            ),
          if (running && total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Categorizing ${NumberFormat.decimalPattern().format(done)}'
                      ' of ${formatCount(total, 'channel')}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(value: done / total),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: double.infinity),
        ],
      ),
    );
  }
}
