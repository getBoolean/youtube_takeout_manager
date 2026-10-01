import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../application/ai_keys.dart';
import '../application/ai_tiers.dart';
import '../application/channel_categories.dart';
import '../application/channel_categorizer.dart';
import '../domain/channel_category.dart';
import '../domain/youtube_topics.dart';
import 'ai_keys_setup.dart';
import 'category_colors.dart';

/// What the user chose, having asked AI for another category.
sealed class CategorySheetResult {
  const CategorySheetResult();
}

/// Use AI's [suggestion] instead.
class AcceptedSuggestion extends CategorySheetResult {
  final ChannelCategory suggestion;

  const AcceptedSuggestion(this.suggestion);
}

/// Keep the category there was.
class KeptCategory extends CategorySheetResult {
  const KeptCategory();
}

/// Explains [channel]'s category in a modal: where it came from. A
/// category not chosen by AI can be sent to AI for another, on the next
/// page; without a key, that opens where keys are added, then comes back.
/// Null when closed without choosing.
Future<CategorySheetResult?> showCategorySheet(
  BuildContext context, {
  required HistoryChannel channel,
}) {
  final categorizer = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(channelCategorizerProvider.notifier);
  // One request however many times the modal builds the page showing it
  // (it measures pages offstage): each ask is paid for.
  final asking = ValueNotifier<Future<ChannelCategory>?>(null);
  void ask() => asking.value = categorizer.suggest(channel)
    // Shown on the page; not an unhandled error if it closed first.
    ..ignore();
  Widget title(String text) => Semantics(
    header: true,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
  const close = Padding(
    padding: EdgeInsetsDirectional.only(end: 8),
    child: CloseButton(),
  );
  return WoltModalSheet.show<CategorySheetResult>(
    context: context,
    pageListBuilder: (_) => [
      WoltModalSheetPage(
        id: CategorySheet.explainId,
        topBarTitle: title(channel.title),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: close,
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
            // Rebuilt as keys are added or turned off.
            ref
              ..watch(aiKeysProvider)
              ..watch(aiTierStatusProvider);
            final modal = WoltModalSheet.of(context);
            return CategorySheet(
              category: category,
              topicLabels: [for (final url in topics) topicLabel(url)],
              canAskAi: ref.read(channelCategorizerProvider.notifier).canAskAi,
              onAskAi: () {
                ask();
                modal.showPageWithId(CategorySheet.askId);
              },
              onAddKeys: () => modal.showPageWithId(AiKeysPages.id),
            );
          },
        ),
      ),
      WoltModalSheetPage(
        id: CategorySheet.askId,
        topBarTitle: title('Ask AI'),
        isTopBarLayerAlwaysVisible: true,
        leadingNavBarWidget: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Builder(
            builder: (context) => IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => WoltModalSheet.of(context).showAtIndex(0),
              icon: const BackButtonIcon(),
            ),
          ),
        ),
        trailingNavBarWidget: close,
        child: CategoryAskPage(asking: asking, onRetry: ask),
      ),
      AiKeysPages.page(),
    ],
  ).whenComplete(asking.dispose);
}

/// A channel's category, large, and where it came from.
class CategorySheet extends StatelessWidget {
  static const youtubeSourceKey = ValueKey('category-source-youtube');
  static const aiSourceKey = ValueKey('category-source-ai');
  static const askAiKey = ValueKey('category-ask-ai');
  static const explainId = 'category-explain';
  static const askId = 'category-ask';

  final ChannelCategory? category;

  /// The topics YouTube gives the channel, by name.
  final List<String> topicLabels;

  /// Whether AI can be asked for another category; without, asking opens
  /// [onAddKeys].
  final bool canAskAi;
  final VoidCallback? onAskAi;
  final VoidCallback? onAddKeys;

  const CategorySheet({
    super.key,
    required this.category,
    this.topicLabels = const [],
    this.canAskAi = false,
    this.onAskAi,
    this.onAddKeys,
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
                AiMark(size: 24, color: scheme.primary),
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
          else ...[
            _Explanation(category: category, topicLabels: topicLabels),
            // AI's choices explain themselves; others can go to AI.
            if (!category.isAi && (onAskAi != null || onAddKeys != null)) ...[
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: canAskAi
                    ? FilledButton.tonalIcon(
                        key: askAiKey,
                        onPressed: onAskAi,
                        icon: tiny ? null : const Icon(Icons.auto_awesome),
                        label: const Text(
                          'Ask AI for another',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : TextButton.icon(
                        key: askAiKey,
                        onPressed: onAddKeys,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                        ),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text(
                          'Ask AI for another',
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
              if (!canAskAi) ...[
                const SizedBox(height: 4),
                Text(
                  'Add an API key for Jev or Claude to ask AI.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

/// What AI suggests instead, as [asking] answers: a progress bar while it's
/// asked, then the suggestion to use or not, which closes the modal; a
/// failure says why in place, to [onRetry].
class CategoryAskPage extends StatelessWidget {
  static const progressKey = ValueKey('category-ask-progress');
  static const acceptKey = ValueKey('category-ask-accept');
  static const denyKey = ValueKey('category-ask-deny');
  static const retryKey = ValueKey('category-ask-retry');
  static const failureKey = ValueKey('category-ask-failure');

  final ValueListenable<Future<ChannelCategory>?> asking;
  final VoidCallback onRetry;

  const CategoryAskPage({
    super.key,
    required this.asking,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: asking,
    builder: (context, request, _) => FutureBuilder(
      future: request,
      builder: (context, answer) => _answer(context, answer),
    ),
  );

  /// Why AI couldn't be asked, and when to try again if the service said.
  static String _failureText(Object? error) {
    if (error is! AiTierFailure) return "AI couldn't be asked: $error";
    final failure = error.failure;
    final resumeAt = resumeAtOf(failure);
    return [
      "AI couldn't be asked: ${failure.message}",
      if (resumeAt != null) 'Try again after ${timeOfDay(resumeAt)}.',
    ].join(' ');
  }

  Widget _answer(BuildContext context, AsyncSnapshot<ChannelCategory> answer) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final suggestion = answer.data;

    final Widget body;
    if (answer.connectionState != ConnectionState.done) {
      body = Column(
        key: progressKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Asking AI for another category…', style: hint),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      );
    } else if (answer.hasError || suggestion == null) {
      final error = answer.error;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              key: failureKey,
              _failureText(error),
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              key: retryKey,
              onPressed: onRetry,
              icon: tiny ? null : const Icon(Icons.refresh),
              label: const Text('Try again', textAlign: TextAlign.center),
            ),
          ),
        ],
      );
    } else {
      final confidence = suggestion.confidence;
      final reason = suggestion.reason;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AiMark(size: 24, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.path?.label ?? 'Uncategorized',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: 8),
                    Text(reason, style: hint),
                  ] else if (confidence != null) ...[
                    const SizedBox(height: 8),
                    Text('Jev is ${_percent(confidence)} sure.', style: hint),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: denyKey,
                onPressed: () =>
                    Navigator.of(context).pop(const KeptCategory()),
                child: const Text('Keep current', textAlign: TextAlign.center),
              ),
              FilledButton(
                key: acceptKey,
                onPressed: () =>
                    Navigator.of(context).pop(AcceptedSuggestion(suggestion)),
                child: const Text(
                  'Use this category',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 24),
      child: body,
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
            switch (category.reason) {
              final reason? => 'Chosen by Claude: $reason',
              null => 'Chosen by Claude.',
            },
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
          CategorySource.user => Text('You chose this.', style: hint),
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
