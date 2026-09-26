import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/sign_in_service.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_thumbnail_fetcher.dart';
import 'package:youtube_takeout_manager/src/features/emoji/application/emoji_name_resolver.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_importer.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_title_fetcher.dart';

part 'app_effects.g.dart';

/// Starts the app's background work, each piece its own provider that
/// listens for what it reacts to. The app listens to this for as long as
/// it runs.
///
/// Effects are services: nothing watches them, so they can read any
/// provider without closing a loop. They change other providers only after
/// an await, never synchronously while starting.
@Riverpod(keepAlive: true)
void appEffects(Ref ref) {
  // Listened to, not watched, so one failing doesn't stop the others.
  ref.listen(legacySignInMigrationProvider, (_, _) {});
  ref.listen(channelThumbnailFetcherProvider, (_, _) {});
  ref.listen(videoTitleFetcherProvider, (_, _) {});
  ref.listen(emojiNameResolverProvider, (_, _) {});
  ref.listen(queueChannelAssignmentProvider, (_, _) {});
}
