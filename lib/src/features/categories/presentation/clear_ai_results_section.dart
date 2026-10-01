import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/confirmed_action_section.dart';
import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../application/ai_keys.dart';
import '../application/ai_results_clearer.dart';
import '../application/channel_categories.dart';
import '../domain/clear_ai.dart';

/// Roughly what categorizing a channel again costs with Claude on its usual
/// model: about 3,000 tokens in and 150 out.
const _claudeDollarsPerChannel = 0.004;

/// The question before clearing AI results: how many [channels] are
/// categorized again the next time History opens, and roughly what that
/// costs with [keys]; a price only with Claude on its usual [model].
String clearAiQuestion({
  required int channels,
  required AiKeys keys,
  required String model,
}) {
  final count = formatCount(channels, 'channel');
  final again = switch (keys) {
    _ when keys.has(AiService.claude) => () {
      if (model != defaultAnthropicModel) {
        return 'Categorizing $count again the next time History opens asks '
            'Claude once for each.';
      }
      final dollars = channels * _claudeDollarsPerChannel;
      final price = dollars < 1 ? r'less than $1' : 'about \$${dollars.ceil()}';
      return 'Categorizing $count again the next time History opens costs '
          '$price with Claude.';
    }(),
    _ when keys.has(AiService.jev) =>
      'Jev categorizes $count again the next time History opens, for next '
          'to nothing.',
    _ => 'Nothing is asked again until you add an AI key.',
  };
  return '$again Clear AI results? What you chose and the tags you edited '
      'are kept.';
}

/// Clearing what AI made for channels, after asking in place how much
/// categorizing them again costs.
class ClearAiResultsSection extends ConsumerWidget {
  static const actionKey = ValueKey('clear-ai-results');
  static const confirmKey = ValueKey('clear-ai-results-confirm');

  const ClearAiResultsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(aiKeysProvider).value ?? AiKeys.none;
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
      question: clearAiQuestion(
        channels: channelsToRedo(categories),
        keys: keys,
        model: anthropicModel,
      ),
      confirmLabel: 'Clear',
      destructive: true,
      done: 'AI results cleared.',
      failed: "Couldn't clear AI results",
      onConfirm: () => ref.read(aiResultsClearerProvider.notifier).clear(),
    );
  }
}
