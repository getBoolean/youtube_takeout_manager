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

/// Signs in, then says so loudly if the channel chosen isn't the viewed one:
/// the sign-in is saved for its own channel, and the viewed one stays signed
/// out.
Future<void> signInToViewedChannel(BuildContext context, WidgetRef ref) async {
  final SignInOutcome outcome;
  try {
    outcome = await ref.read(authProvider.notifier).signIn();
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
    case SignedInOtherChannel(:final profile, :final viewedChannelId):
      final viewed = ref.read(viewedChannelProvider);
      final takeouts = await ref.read(savedTakeoutsProvider.future);
      final chosenTakeout = takeouts
          .where((t) => t.channelIds.contains(profile.channelId))
          .firstOrNull;
      if (!context.mounted) return;
      final view = await showDialog<bool>(
        context: context,
        builder: (_) => SignedInOtherChannelDialog(
          chosen: profile,
          viewedChannelId: viewedChannelId,
          viewedTitle: viewed?.channelId == viewedChannelId
              ? viewed?.title
              : null,
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

/// The channel chosen when signing in isn't the viewed one.
class SignedInOtherChannelDialog extends StatelessWidget {
  final SignInProfile chosen;
  final String viewedChannelId;
  final String? viewedTitle;

  /// Whether a saved takeout has the chosen channel, so it can be viewed.
  /// The dialog then returns true if the user chooses to.
  final bool canViewChosen;

  const SignedInOtherChannelDialog({
    super.key,
    required this.chosen,
    required this.viewedChannelId,
    this.viewedTitle,
    this.canViewChosen = false,
  });

  @override
  Widget build(BuildContext context) {
    final chosenName = chosen.channelTitle ?? chosen.channelId;
    final viewedName = viewedTitle ?? viewedChannelId;
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
            ),
            const SizedBox(height: 12),
            ChannelIdentity(
              label: "You're viewing",
              channelId: viewedChannelId,
              title: viewedTitle,
            ),
            const SizedBox(height: 16),
            Text(
              'The sign-in is saved for $chosenName and used whenever you '
              "view it. $viewedName isn't signed in, so it can't delete "
              'through the YouTube API. To sign it in, sign in again and '
              'choose $viewedName when Google asks.',
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
