import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/auth_notifier.dart';
import 'package:youtube_takeout_manager/src/features/authentication/data/google_auth_repository.dart';
import 'package:youtube_takeout_manager/src/features/quota/application/quota_notifier.dart';
import 'package:youtube_takeout_manager/src/features/quota/domain/quota_operation.dart';
import '../data/youtube_channel_repository.dart';

part 'signed_in_channel_provider.g.dart';

/// The YouTube channel of the signed-in Google account, or null when signed
/// out. Throws if it can't be looked up or the account has no channel.
///
/// Failures aren't retried automatically, so an import waiting on this fails
/// right away; invalidate it to look the channel up again.
@Riverpod(keepAlive: true, retry: _noRetry)
Future<String?> signedInChannelId(Ref ref) async {
  final authState = ref.watch(authProvider);
  if (authState == null) return null;

  final client = ref
      .read(googleAuthRepositoryProvider)
      .getAuthenticatedClient(authState.accessToken);
  try {
    final channelId = await ref
        .read(youtubeChannelRepositoryProvider)
        .fetchMyChannelId(client);
    await ref
        .read(quotaProvider.notifier)
        .recordUsage(QuotaOperation.channelsList);
    if (channelId == null) {
      throw StateError('The signed-in Google account has no YouTube channel.');
    }
    return channelId;
  } finally {
    client.close();
  }
}

Duration? _noRetry(int retryCount, Object error) => null;
