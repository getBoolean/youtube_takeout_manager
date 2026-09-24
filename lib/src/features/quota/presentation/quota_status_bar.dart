import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/quota_operation.dart';
import '../service/quota_notifier.dart';

const _progressMorphDuration = Duration(milliseconds: 450);
const _colorMorphDuration = Duration(milliseconds: 250);

class QuotaStatusBar extends ConsumerWidget {
  const QuotaStatusBar({super.key});

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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ClipRRect(
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
                        minHeight: 6,
                        color: color,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
