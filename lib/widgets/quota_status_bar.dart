import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/quota_provider.dart';

class QuotaStatusBar extends ConsumerWidget {
  const QuotaStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaAsync = ref.watch(quotaProvider);

    return quotaAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (quota) {
        final used = quota.deletesRemaining;
        final total = quota.dailyLimit ~/ 50;
        final deletesUsed = total - used;
        final progress = total > 0 ? deletesUsed / total : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$deletesUsed / $total deletes used today',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '$used remaining',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
