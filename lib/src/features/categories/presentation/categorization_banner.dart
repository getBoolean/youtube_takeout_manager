import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import '../application/ai_keys.dart';
import '../application/ai_tiers.dart';
import '../application/categorization_progress.dart';

/// A notice about AI, such as a key rejected, until dismissed. Over
/// channels or categories ([grouped]), also how far along categorizing
/// them is, as a slim bar with a line saying so that folds away when done,
/// or, when nothing can categorize them, what would.
class CategorizationBanner extends ConsumerWidget {
  static const hintKey = ValueKey('categorization-hint');

  final bool grouped;

  const CategorizationBanner({super.key, this.grouped = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:running, :done, :total) = ref.watch(categorizationProgressProvider);
    final (:disabled, :notice) = ref.watch(aiTierStatusProvider);
    final keys = ref.watch(aiKeysProvider).value ?? AiKeys.none;
    // Signed out, YouTube's topics can't be asked for.
    final stuck =
        ref.watch(readSessionChannelIdProvider) == null &&
        !AiService.values.any(
          (service) => keys.has(service) && !disabled.contains(service),
        );
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
          if (grouped && stuck)
            Padding(
              key: hintKey,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Sign in to get categories from YouTube, or add an AI key '
                'under Takeouts › AI categories.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (grouped && running && total > 0)
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
