import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../application/channel_categories.dart';
import '../domain/channel_category.dart';
import '../domain/youtube_topics.dart';
import 'category_chip.dart';

/// Explains [channel]'s category in a modal: where it came from.
Future<void> showCategorySheet(
  BuildContext context, {
  required HistoryChannel channel,
}) => WoltModalSheet.show<void>(
  context: context,
  pageListBuilder: (_) => [
    WoltModalSheetPage(
      topBarTitle: Semantics(
        header: true,
        child: Text(
          channel.title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: const Padding(
        padding: EdgeInsetsDirectional.only(end: 8),
        child: CloseButton(),
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final category = ref.watch(
            channelCategoriesProvider.select((m) => m.value?[channel.key]),
          );
          final topics =
              ref.watch(
                channelDetailsProvider.select(
                  (m) => m.value?[channel.channelId]?.topicUrls,
                ),
              ) ??
              const <String>[];
          return CategorySheet(
            category: category,
            topicLabels: [for (final url in topics) topicLabel(url)],
          );
        },
      ),
    ),
  ],
);

/// A channel's category, large, and where it came from.
class CategorySheet extends StatelessWidget {
  static const youtubeSourceKey = ValueKey('category-source-youtube');
  static const aiSourceKey = ValueKey('category-source-ai');

  final ChannelCategory? category;

  /// The topics YouTube gives the channel, by name.
  final List<String> topicLabels;

  const CategorySheet({
    super.key,
    required this.category,
    this.topicLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final category = this.category;
    final path = category?.path;
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (category?.isAi ?? false) ...[
                Icon(ChannelCategoryChip.aiIcon, color: scheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  path?.label ?? 'Uncategorized',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (category == null)
            Text('Not categorized yet.', style: hint)
          else
            _Explanation(category: category, topicLabels: topicLabels),
        ],
      ),
    );
  }
}

String _percent(double odds) => '${(odds * 100).round()}%';

/// Where [category] came from: YouTube's topics, and how sure Jev was of
/// them; or which AI chose it, how sure, and what came next.
class _Explanation extends StatelessWidget {
  final ChannelCategory category;
  final List<String> topicLabels;

  const _Explanation({required this.category, required this.topicLabels});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final category = this.category;
    final confidence = category.confidence;
    final jevAgreed = category.jevAgreed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (category.source) {
          CategorySource.claude => Text(
            key: CategorySheet.aiSourceKey,
            'Chosen by Claude.',
            style: hint,
          ),
          CategorySource.jev => Text(
            key: CategorySheet.aiSourceKey,
            confidence == null
                ? 'Chosen by Jev from the known categories.'
                : 'Chosen by Jev from the known categories, '
                      '${_percent(confidence)} sure.',
            style: hint,
          ),
          CategorySource.youtube => Text(
            key: CategorySheet.youtubeSourceKey,
            topicLabels.isEmpty
                ? 'YouTube gives this channel no topics to tell its category '
                      'by.'
                : 'From the topics YouTube gives this channel: '
                      '${topicLabels.join(', ')}.',
            style: hint,
          ),
        },
        if (category.source == CategorySource.youtube && jevAgreed != null) ...[
          const SizedBox(height: 8),
          Text(
            'Jev checked it: ${_percent(jevAgreed)} sure it fits.',
            style: hint,
          ),
        ],
        if (category.source == CategorySource.jev &&
            category.runnersUp.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text('Next most likely', style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 4),
          for (final runner in category.runnersUp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${runner.path.label} · ${_percent(runner.score)}',
                style: hint,
              ),
            ),
        ],
      ],
    );
  }
}
