import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/confirmed_action_section.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../application/ai_results_clearer.dart';
import '../application/channel_categories.dart';
import '../domain/clear_ai.dart';

/// The question before clearing AI results: how many [channels] go back to
/// what YouTube's topics give, until the user next runs categorizing with
/// AI. Nothing is asked of AI before then, so there's no price to name.
String clearAiQuestion({required int channels}) =>
    'Clear AI results? ${formatCount(channels, 'channel')} go back to '
    "YouTube's categories and lose the tags AI named, until you next "
    'categorize with AI. What you chose and the tags you edited are kept.';

/// Clearing what AI made for channels, after asking in place.
class ClearAiResultsSection extends ConsumerWidget {
  static const actionKey = ValueKey('clear-ai-results');
  static const confirmKey = ValueKey('clear-ai-results-confirm');

  const ClearAiResultsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(channelCategoriesProvider).value ?? const {};
    return ConfirmedActionSection(
      actionKey: actionKey,
      confirmKey: confirmKey,
      title: 'Clear AI results',
      description:
          "Puts channels AI categorized back to YouTube's categories, and "
          'removes the tags AI named. What you chose, the tags you edited, '
          "and categories from YouTube's topics are kept.",
      icon: Icons.auto_delete_outlined,
      actionLabel: 'Clear AI results',
      question: clearAiQuestion(channels: channelsToRedo(categories)),
      confirmLabel: 'Clear',
      destructive: true,
      done: 'AI results cleared.',
      failed: "Couldn't clear AI results",
      onConfirm: () => ref.read(aiResultsClearerProvider.notifier).clear(),
    );
  }
}
