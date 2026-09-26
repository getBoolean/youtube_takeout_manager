import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import '../domain/sign_in_notice.dart';

/// Why the channel [targetChannelId] didn't end up signed in, on its row.
class SignInNoticeBanner extends StatelessWidget {
  final SignInNotice notice;
  final String targetChannelId;
  final String? targetTitle;
  final String? targetThumbnailUrl;

  /// Views the channel chosen instead, when a saved takeout has it.
  final VoidCallback? onViewChosen;
  final VoidCallback onDismiss;

  const SignInNoticeBanner({
    super.key,
    required this.notice,
    required this.targetChannelId,
    this.targetTitle,
    this.targetThumbnailUrl,
    this.onViewChosen,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final targetName = targetTitle ?? targetChannelId;
    return switch (notice) {
      OtherChannelChosen(:final chosen) => NoticeBanner(
        title: 'Signed in with another channel',
        onDismiss: onDismiss,
        actions: [
          if (onViewChosen case final view?)
            TextButton(
              onPressed: view,
              child: Text(
                'View ${chosen.channelTitle ?? chosen.channelId}',
                textAlign: TextAlign.center,
              ),
            ),
        ],
        children: [
          ChannelIdentity(
            label: 'You chose',
            channelId: chosen.channelId,
            title: chosen.channelTitle,
            thumbnailUrl: chosen.channelThumbnailUrl,
          ),
          ChannelIdentity(
            label: 'Signing in for',
            channelId: targetChannelId,
            title: targetTitle,
            thumbnailUrl: targetThumbnailUrl,
          ),
          Text(
            'The sign-in is saved for '
            '${chosen.channelTitle ?? chosen.channelId} and used whenever you '
            "view it. $targetName isn't signed in, so it can't delete through "
            'the YouTube API. To sign it in, sign in again and choose '
            '$targetName when Google asks.',
          ),
        ],
      ),
      NoYouTubeChannel() => NoticeBanner(
        title: 'No YouTube channel',
        onDismiss: onDismiss,
        children: [
          Text(
            "The Google account you chose doesn't have a YouTube channel, so "
            "it can't delete anything. Nothing was saved. Sign in again and "
            'choose $targetName when Google asks.',
          ),
        ],
      ),
      SignInFailed(:final message) => NoticeBanner(
        title: 'Sign-in failed',
        onDismiss: onDismiss,
        children: [Text(message)],
      ),
      SignInStoppedWorking() => NoticeBanner(
        title: 'Sign-in stopped working',
        onDismiss: onDismiss,
        children: [
          Text(
            "Google no longer accepts $targetName's sign-in, e.g. its access "
            'was removed. Sign in again to delete through the YouTube API.',
          ),
        ],
      ),
    };
  }
}
