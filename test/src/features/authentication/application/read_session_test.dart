import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/saved_sign_ins.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/authentication/domain/sign_in_profile.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/channel_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/channels/data/youtube_channel_repository.dart';
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

/// Only another channel of the account is signed in, not the viewed one.
class _SignIns extends SavedSignIns {
  @override
  Future<Map<String, SignInProfile>> build() async => const {
    'UCother': SignInProfile(channelId: 'UCother'),
  };
}

/// A client that says which channel's sign-in it was made with.
class _SessionClient extends http.BaseClient {
  final String channelId;

  _SessionClient(this.channelId);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();
}

class _Sessions extends GoogleAuthRepository {
  @override
  Future<AccessCredentials?> requestCredentials() async => null;

  @override
  bool isUsable(AccessCredentials credentials) => true;

  @override
  http.Client clientFor(AccessCredentials credentials) =>
      throw UnimplementedError();

  @override
  void addSession(
    String channelId,
    AccessCredentials credentials, {
    required void Function(AccessCredentials credentials) onRefreshed,
  }) {}

  @override
  bool hasSession(String channelId) => channelId == 'UCother';

  @override
  http.Client getAuthenticatedClient(String channelId) =>
      _SessionClient(channelId);

  @override
  Future<void> closeSession(String channelId, {bool revoke = false}) async {}
}

/// Records which sign-in fetched which channels' pictures.
class _Channels extends YoutubeChannelRepository {
  final sessions = <String>[];
  final fetched = <String>{};

  @override
  Future<Map<String, String>> fetchChannelThumbnails(
    http.Client authClient,
    Set<String> channelIds,
  ) async {
    sessions.add((authClient as _SessionClient).channelId);
    fetched.addAll(channelIds);
    return {for (final id in channelIds) id: 'https://yt3.ggpht.com/$id'};
  }
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a signed-out viewed channel still gets channel pictures, read with '
      'another saved sign-in', () async {
    final channels = _Channels();
    final container = ProviderContainer(
      overrides: [
        takeoutProvider.overrideWith(_Takeout.new),
        takeoutSelectionProvider.overrideWith(_Selection.new),
        savedSignInsProvider.overrideWith(_SignIns.new),
        googleAuthRepositoryProvider.overrideWithValue(_Sessions()),
        youtubeChannelRepositoryProvider.overrideWithValue(channels),
        channelCacheRepositoryProvider.overrideWithValue(_NoCache()),
        channelsProvider.overrideWithValue(const []),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(readSessionChannelIdProvider, (_, _) {})
      ..listen(channelThumbnailsProvider, (_, _) {})
      ..listen(channelThumbnailFetcherProvider, (_, _) {});
    await container.read(takeoutProvider.future);
    await container.read(takeoutSelectionProvider.future);
    await container.read(savedSignInsProvider.future);
    await container.read(channelThumbnailsProvider.future);

    final fetcher = container.read(channelThumbnailFetcherProvider.notifier)
      ..queueChannelIds({'UC1', 'UC2'});
    await fetcher.flushQueue();

    expect(channels.sessions, ['UCother']);
    expect(channels.fetched, {'UC1', 'UC2'});
    expect(
      container.read(channelThumbnailsProvider).value,
      containsPair('UC1', 'https://yt3.ggpht.com/UC1'),
    );
  });
}
