import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/saved_takeouts.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/takeout_switcher.dart';
import '../application/auth_notifier.dart';
import '../domain/sign_in_outcome.dart';
import '../domain/sign_in_profile.dart';

/// Signs the viewed channel in. See [signInToChannel].
Future<void> signInToViewedChannel(BuildContext context, WidgetRef ref) =>
    signInToChannel(context, ref);

/// Signs [channelId] in (else the viewed channel), then says so loudly if the
/// channel chosen isn't it: the sign-in is saved for its own channel, and
/// [channelId] stays signed out.
Future<void> signInToChannel(
  BuildContext context,
  WidgetRef ref, {
  String? channelId,
}) async {
  final SignInOutcome outcome;
  try {
    outcome = await ref
        .read(authProvider.notifier)
        .signIn(targetChannelId: channelId);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    }
    return;
  }
  if (!context.mounted) return;

  switch (outcome) {
    case SignedInOtherChannel(:final profile, :final targetChannelId):
      final target = ref
          .read(takeoutChannelsProvider)
          .where((c) => c.channelId == targetChannelId)
          .firstOrNull;
      final takeouts = await ref.read(savedTakeoutsProvider.future);
      final chosenTakeout = takeouts
          .where((t) => t.channelIds.contains(profile.channelId))
          .firstOrNull;
      if (!context.mounted) return;
      final view = await showDialog<bool>(
        context: context,
        builder: (_) => SignedInOtherChannelDialog(
          chosen: profile,
          targetChannelId: targetChannelId,
          targetTitle: target?.title,
          targetThumbnailUrl: target?.thumbnailUrl,
          canViewChosen: chosenTakeout != null,
        ),
      );
      if (view == true && chosenTakeout != null && context.mounted) {
        await switchToTakeout(
          context,
          ref,
          chosenTakeout,
          channelId: profile.channelId,
        );
      }
    case SignInNoChannel():
      await showDialog<void>(
        context: context,
        builder: (_) => const NoYouTubeChannelDialog(),
      );
    case SignedIn() || SignInCancelled():
      break;
  }
}

/// The channel chosen when signing in isn't the one being signed in.
class SignedInOtherChannelDialog extends StatelessWidget {
  final SignInProfile chosen;
  final String targetChannelId;
  final String? targetTitle;
  final String? targetThumbnailUrl;

  /// Whether a saved takeout has the chosen channel, so it can be viewed.
  /// The dialog then returns true if the user chooses to.
  final bool canViewChosen;

  const SignedInOtherChannelDialog({
    super.key,
    required this.chosen,
    required this.targetChannelId,
    this.targetTitle,
    this.targetThumbnailUrl,
    this.canViewChosen = false,
  });

  @override
  Widget build(BuildContext context) {
    final chosenName = chosen.channelTitle ?? chosen.channelId;
    final targetName = targetTitle ?? targetChannelId;
    return AlertDialog(
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      icon: const Icon(Icons.warning_amber_outlined),
      title: const Text('Signed in with another channel'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChannelIdentity(
              label: 'You chose',
              channelId: chosen.channelId,
              title: chosen.channelTitle,
              thumbnailUrl: chosen.channelThumbnailUrl,
            ),
            const SizedBox(height: 12),
            ChannelIdentity(
              label: 'Signing in for',
              channelId: targetChannelId,
              title: targetTitle,
              thumbnailUrl: targetThumbnailUrl,
            ),
            const SizedBox(height: 16),
            Text(
              'The sign-in is saved for $chosenName and used whenever you '
              "view it. $targetName isn't signed in, so it can't delete "
              'through the YouTube API. To sign it in, sign in again and '
              'choose $targetName when Google asks.',
            ),
          ],
        ),
      ),
      actions: [
        if (canViewChosen)
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('View $chosenName'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// The Google account chosen when signing in has no YouTube channel.
class NoYouTubeChannelDialog extends StatelessWidget {
  const NoYouTubeChannelDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      title: const Text('No YouTube channel'),
      content: const Text(
        "The Google account you chose doesn't have a YouTube channel, so it "
        "can't delete anything. Nothing was saved. Sign in again and choose "
        'the account or channel your takeout is from.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
