import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/channel_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_selection_notifier.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/loaded_takeout.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_selection.dart';

class _Takeout extends TakeoutNotifier {
  @override
  Future<LoadedTakeout?> build() async => LoadedTakeout(
    id: 'UCme',
    data: TakeoutData(
      comments: [
        Comment(
          commentId: 'c1',
          channelId: 'UCme',
          createdAt: DateTime(2026),
          price: 0,
          rawCommentText: '{"text":"hi"}',
          displayText: 'hi',
          videoId: 'v1',
        ),
      ],
      liveChats: const [],
      subscriptionsByChannelId: const {},
    ),
  );
}

class _Selection extends TakeoutSelectionNotifier {
  @override
  Future<TakeoutSelection?> build() async =>
      const TakeoutSelection(takeoutId: 'UCme');
}

class _SignIns extends SavedSignIns {
  @override
  Future<Map<String, SignInProfile>> build() async => const {};
}

class _NoCache implements ChannelCacheRepository {
  @override
  Future<Map<String, String>> loadCachedThumbnails() async => const {};

  @override
  Future<void> saveThumbnails(Map<String, String> thumbnails) async {}

  @override
  Future<void> clearThumbnails() async {}
}

void main() {
  test('channel pictures can be fetched with the sign-in that reads them, '
      "which doesn't depend on those pictures", () async {
    final container = ProviderContainer(
      overrides: [
        takeoutProvider.overrideWith(_Takeout.new),
        takeoutSelectionProvider.overrideWith(_Selection.new),
        savedSignInsProvider.overrideWith(_SignIns.new),
        channelCacheRepositoryProvider.overrideWithValue(_NoCache()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(readSessionChannelIdProvider, (_, _) {});
    container.listen(channelThumbnailsProvider, (_, _) {});
    await container.read(takeoutProvider.future);
    await container.read(takeoutSelectionProvider.future);
    await container.read(savedSignInsProvider.future);
    container.read(readSessionChannelIdProvider);

    // Enough channels to fetch a batch, which reads the sign-in to use.
    expect(
      () => container.read(channelThumbnailsProvider.notifier).queueChannelIds(
        {for (var i = 0; i < 10; i++) 'UC$i'},
      ),
      returnsNormally,
    );
  });
}
