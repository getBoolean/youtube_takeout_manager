import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/common_widgets/confirmed_action_section.dart';
import '../application/google_cloud_client_setup.dart';
import '../data/oauth_client_repository.dart';

/// The Google Cloud client users bring when the build has none: setting one
/// up through [onSetUp], or the one set up, to change through [onChange] or
/// remove after asking in place. Neither while [deletionRunning].
class GoogleCloudSection extends ConsumerWidget {
  static const setUpKey = ValueKey('google-cloud-set-up');
  static const changeKey = ValueKey('google-cloud-change');
  static const pausedKey = ValueKey('google-cloud-paused');

  static const _title = 'Google Cloud client';

  final bool deletionRunning;
  final VoidCallback onSetUp;
  final VoidCallback onChange;

  const GoogleCloudSection({
    super.key,
    required this.deletionRunning,
    required this.onSetUp,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final client = ref.watch(oauthClientProvider).value;
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (client == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Sign-in, video titles, channel pictures and deleting via the '
            'YouTube API need your own Google Cloud client. It is free, and '
            'its daily API quota is yours alone.',
            style: hint,
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            key: setUpKey,
            onPressed: onSetUp,
            icon: isTinyWidth(context)
                ? null
                : const Icon(Icons.cloud_outlined),
            label: const Text('Set up', textAlign: TextAlign.center),
          ),
        ],
      );
    }

    final id = Text(
      client.id,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
    );
    const description =
        'Signs in and uses the YouTube API through your own Google Cloud '
        'project.';
    if (deletionRunning) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(description, style: hint),
          const SizedBox(height: 12),
          id,
          const SizedBox(height: 4),
          Text(
            key: pausedKey,
            'Pause the deletion to change or remove the client.',
            style: hint,
          ),
        ],
      );
    }
    return ConfirmedActionSection(
      title: _title,
      description: description,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          id,
          TextButton.icon(
            key: changeKey,
            onPressed: onChange,
            icon: isTinyWidth(context) ? null : const Icon(Icons.edit_outlined),
            label: const Text('Change', textAlign: TextAlign.center),
          ),
        ],
      ),
      icon: Icons.link_off,
      actionLabel: 'Remove client',
      question:
          'Remove the client? Every channel is signed out, and sign-in, video '
          'titles, channel pictures and deleting via the API stay off until '
          'you set one up again.',
      confirmLabel: 'Remove',
      destructive: true,
      done: 'Client removed.',
      failed: "Couldn't remove the client",
      onConfirm: () =>
          ref.read(googleCloudClientSetupProvider.notifier).remove(),
    );
  }
}
