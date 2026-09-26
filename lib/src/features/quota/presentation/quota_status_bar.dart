import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/quota_notifier.dart';
import '../domain/quota_operation.dart';

const _progressMorphDuration = Duration(milliseconds: 450);
const _colorMorphDuration = Duration(milliseconds: 250);

/// Today's YouTube API quota usage.
///
/// [compact] shows only the deletes left and a note that the quota applies
/// to API deletes, not My Activity, for where the user picks how to delete.
class QuotaStatusBar extends ConsumerWidget {
  final EdgeInsetsGeometry padding;
  final bool compact;

  const QuotaStatusBar({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaAsync = ref.watch(quotaProvider);

    return quotaAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (quota) {
        final used = quota.unitsUsed;
        final total = quota.dailyLimit;
        final remaining = quota.unitsRemaining;
        final progress = total > 0 ? used / total : 0.0;
        final deletesAffordable = quota.affordableOperations(
          QuotaOperation.deleteComment.cost,
        );

        final defaultProgressColor = Theme.of(context).colorScheme.primary;
        final targetColor = switch (progress) {
          >= 0.9 => Theme.of(context).colorScheme.error,
          >= 0.75 => Colors.orange,
          _ => defaultProgressColor,
        };

        // Build breakdown parts for non-zero operations.
        final parts = <String>[];
        final deleteUnits =
            quota.usageFor(QuotaOperation.deleteComment) +
            quota.usageFor(QuotaOperation.deleteLiveChat);
        final videoUnits = quota.usageFor(QuotaOperation.videosList);
        final channelUnits = quota.usageFor(QuotaOperation.channelsList);
        if (deleteUnits > 0) parts.add('Deletes: $deleteUnits');
        if (videoUnits > 0) parts.add('Videos: $videoUnits');
        if (channelUnits > 0) parts.add('Channels: $channelUnits');

        final theme = Theme.of(context);
        final bar = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: progress, end: progress),
            duration: _progressMorphDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return TweenAnimationBuilder<Color?>(
                tween: ColorTween(begin: targetColor, end: targetColor),
                duration: _colorMorphDuration,
                builder: (context, color, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: compact ? 4 : 6,
                  color: color,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              );
            },
          ),
        );

        if (compact) {
          return Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Intl.plural(
                    deletesAffordable,
                    one: 'YouTube API · ~1 delete left today',
                    other:
                        'YouTube API · ~$deletesAffordable deletes left today',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                bar,
                const SizedBox(height: 4),
                Text(
                  'Only deletes via the API count. My Activity has no limit.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wraps onto two lines when narrow, e.g. in the Takeouts dialog.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Text(
                    '$used / $total units used today',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '$remaining remaining (~$deletesAffordable deletes)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (parts.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  parts.join(' · '),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              bar,
            ],
          ),
        );
      },
    );
  }
}
