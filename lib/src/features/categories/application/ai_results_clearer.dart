import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel_details.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_shown.dart';
import '../domain/clear_ai.dart';
import '../domain/youtube_topics.dart';
import 'channel_categories.dart';
import 'channel_categorizer.dart';
import 'channel_tags.dart';

part 'ai_results_clearer.g.dart';

/// Clears what AI made for channels, keeping what the user decided, as
/// [clearAiResults] says: the run under way is stopped first, so nothing it
/// answers is kept, and the next time History opens, channels are
/// categorized again.
///
/// A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class AiResultsClearer extends _$AiResultsClearer {
  @override
  void build() {}

  Future<void> clear() async {
    // First, so a run asked for while clearing, such as one without a
    // service an answer turned off, waits for History too.
    ref.read(historyShownProvider.notifier).reset();
    await ref.read(channelCategorizerProvider.notifier).stopRun();
    final details = await ref
        .read(channelDetailsProvider.future)
        .catchError((Object _) => const <String, ChannelDetails>{});
    final cleared = clearAiResults(
      (
        categories: await ref.read(channelCategoriesProvider.future),
        custom: await ref.read(customCategoriesProvider.future),
        tags: await ref.read(tagNamesProvider.future),
      ),
      youtubeOf: (key) =>
          youtubeCandidates(details[key]?.topicUrls ?? const []),
      now: DateTime.now().toUtc(),
    );
    await ref
        .read(channelCategoriesProvider.notifier)
        .replaceAll(cleared.categories);
    await ref
        .read(customCategoriesProvider.notifier)
        .replaceAll(cleared.custom);
    await ref.read(tagNamesProvider.notifier).replaceAll(cleared.tags);
  }
}
