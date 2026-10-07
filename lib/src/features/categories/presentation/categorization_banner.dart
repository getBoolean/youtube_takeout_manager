import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import '../application/ai_keys.dart';
import '../application/ai_tiers.dart';
import '../application/categorization_progress.dart';
import '../application/channel_categorizer.dart';
import '../application/pending_ai_work.dart';
import '../domain/run_estimate.dart';
import 'categorize_window.dart';

/// A notice about AI, such as a key rejected, until dismissed; and how
/// categorizing with AI goes. While the user's run goes, how far along it
/// is, as a slim bar with a line saying so, what Claude has cost so far,
/// and Stop. Once they stopped it, Continue. Otherwise, with a key, how
/// many channels wait for AI, and Categorize, which opens the window to run
/// it. Over channels or categories ([grouped]), when nothing can categorize
/// them, what would. YouTube's own categorizing shows nothing.
class CategorizationBanner extends ConsumerWidget {
  static const hintKey = ValueKey('categorization-hint');
  static const stopKey = ValueKey('categorization-stop');
  static const continueKey = ValueKey('categorization-continue');
  static const categorizeKey = ValueKey('categorization-categorize');

  final bool grouped;

  const CategorizationBanner({super.key, this.grouped = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(categorizationProgressProvider);
    final (:disabled, :notice) = ref.watch(aiTierStatusProvider);
    final keys = ref.watch(aiKeysProvider).value ?? AiKeys.none;
    final usable = AiService.values.any(
      (service) => keys.has(service) && !disabled.contains(service),
    );
    // Signed out, YouTube's topics can't be asked for.
    final stuck = ref.watch(readSessionChannelIdProvider) == null && !usable;
    final summary = ref.watch(pendingAiWorkProvider);
    final usage = ref.watch(claudeUsageProvider);
    final theme = Theme.of(context);
    final small = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final count = NumberFormat.decimalPattern();
    // Read when pressed: showing the banner starts no categorizer.
    ChannelCategorizer categorizer() =>
        ref.read(channelCategorizerProvider.notifier);
    final tiny = isTinyWidth(context);
    const wand = Icon(Icons.auto_fix_high);
    final waiting = summary == null
        ? 0
        : summary.categorize + summary.redo + summary.tags;

    Widget line(Widget text, Widget? action) => Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 4,
      children: [text, ?action],
    );

    final Widget? status;
    if (progress.running && progress.ai) {
      final spent = usage.input + usage.output > 0
          ? claudeDollars(usage.input, usage.output)
          : null;
      status = Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(
              Text(
                [
                  if (progress.stopping)
                    'Stopping once the answers asked for come'
                  else
                    '${progress.redo ? 'Categorizing again with updated prompts: ' : 'Categorizing with AI: '}'
                        '${count.format(progress.done)} of '
                        '${formatCount(progress.total, 'channel')}',
                  if (spent != null)
                    'Claude so far: about \$${spent.toStringAsFixed(2)}',
                ].join(' · '),
                style: small,
              ),
              OutlinedButton.icon(
                key: stopKey,
                onPressed: progress.stopping
                    ? null
                    : () => categorizer().stop(),
                icon: tiny ? null : const Icon(Icons.stop_circle_outlined),
                label: Text(
                  progress.stopping ? 'Stopping…' : 'Stop',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.total == 0
                    ? null
                    : progress.done / progress.total,
              ),
            ),
          ],
        ),
      );
    } else if (progress.interrupted && usable && waiting > 0) {
      status = line(
        Text(
          'Categorizing with AI stopped, with '
          '${formatCount(waiting, 'channel')} left',
          style: small,
        ),
        FilledButton.tonalIcon(
          key: continueKey,
          onPressed: () => categorizer().run(),
          icon: tiny ? null : wand,
          label: const Text('Continue', textAlign: TextAlign.center),
        ),
      );
    } else if (usable && summary != null && summary.hasWork) {
      status = line(
        Text(
          waiting > 0
              ? "${formatCount(waiting, 'channel')} aren't categorized with "
                    'AI yet'
              : '${formatCount(summary.checks, 'channel')} to check for '
                    'your tags',
          style: small,
        ),
        FilledButton.tonalIcon(
          key: categorizeKey,
          onPressed: () => showCategorizeWindow(context),
          icon: tiny ? null : wand,
          label: const Text('Categorize', textAlign: TextAlign.center),
        ),
      );
    } else {
      status = null;
    }

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
          if (status case final status?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: status,
            )
          else
            const SizedBox(width: double.infinity),
        ],
      ),
    );
  }
}
