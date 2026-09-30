import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_processing.dart';
import '../application/google_cloud_client_setup.dart';
import '../application/saved_sign_ins.dart';
import '../data/google_auth_repository.dart';
import '../data/oauth_client_repository.dart';
import 'google_cloud_client_form.dart';

/// Opens the Google Cloud setup pages of the modal [context] is in: from the
/// first step, or, when [change] is set, at the client itself.
void showGoogleCloudSetup(BuildContext context, {bool change = false}) =>
    WoltModalSheet.of(context).showPageWithId(
      change ? GoogleCloudSetupPages.pasteId : GoogleCloudSetupPages.firstId,
    );

/// Walks through making a Google Cloud client and pastes it in, as pages of
/// a Wolt modal sheet after its first page, so this device signs in and uses
/// the YouTube API through the user's own project and its own daily quota.
/// Each step shows how far along it is. Saving the client, or cancelling,
/// goes back to the modal's first page, where the user left off.
abstract final class GoogleCloudSetupPages {
  static const firstId = 'google-cloud-setup-first';
  static const pasteId = 'google-cloud-setup-paste';
  static const nextKey = ValueKey('google-cloud-setup-next');
  static const cancelKey = ValueKey('google-cloud-setup-cancel');
  static const copyOriginKey = ValueKey('google-cloud-setup-copy-origin');

  /// The pages. On [web] the client is a "Web application" one, allowed to
  /// sign in from [origin], this app's address by default.
  static List<SliverWoltModalSheetPage> build({
    bool web = kIsWeb,
    String? origin,
  }) {
    origin ??= web ? Uri.base.origin : null;
    final steps = <({String title, Widget content})>[
      (
        title: 'Create a project',
        content: const _StepText(
          paragraphs: [
            'Sign in to Google Cloud with any Google account and create a '
                "project. It's free, and no billing account is needed.",
            'The project gets its own daily YouTube API quota, used by this '
                'device only.',
          ],
          link: (
            label: 'Open Google Cloud',
            url: 'https://console.cloud.google.com/projectcreate',
          ),
        ),
      ),
      (
        title: 'Turn on the YouTube API',
        content: const _StepText(
          paragraphs: ['In your project, enable YouTube Data API v3.'],
          link: (
            label: 'Open YouTube Data API v3',
            url:
                'https://console.cloud.google.com/apis/library/'
                'youtube.googleapis.com',
          ),
        ),
      ),
      (
        title: 'Set up Google sign-in',
        content: const _StepText(
          paragraphs: [
            'Open Google Auth Platform and get started:',
            '• Branding: any app name, and your email.',
            '• Audience: choose External. Under Test users, add the Google '
                'account your channels belong to. Without it, Google blocks '
                'sign-in with error 403.',
            '• Data Access: add the scope below.',
          ],
          code: youtubeScope,
          link: (
            label: 'Open Google Auth Platform',
            url: 'https://console.cloud.google.com/auth/overview',
          ),
        ),
      ),
      (
        title: 'Create a client',
        content: web
            ? _StepText(
                paragraphs: const [
                  'Under Clients, create a client and choose Web '
                      'application.',
                  "Under Authorized JavaScript origins, add this app's "
                      'address:',
                ],
                code: origin,
                copyKey: copyOriginKey,
                link: const (label: 'Open Clients', url: _clientsUrl),
              )
            : const _StepText(
                paragraphs: [
                  'Under Clients, create a client and choose Desktop app.',
                  'Google then shows its client ID and secret. Keep the page '
                      'open: the secret is only shown once.',
                ],
                link: (label: 'Open Clients', url: _clientsUrl),
              ),
      ),
      (title: 'Paste your client', content: _PasteStep(web: web)),
    ];
    return [
      for (final (index, (:title, :content)) in steps.indexed)
        WoltModalSheetPage(
          id: switch (index) {
            0 => firstId,
            _ when index == steps.length - 1 => pasteId,
            _ => 'google-cloud-setup-$index',
          },
          topBarTitle: const _TopBarTitle('Set up Google sign-in'),
          isTopBarLayerAlwaysVisible: true,
          leadingNavBarWidget: const _Back(),
          trailingNavBarWidget: const _Close(),
          stickyActionBar: index < steps.length - 1 ? const _Next() : null,
          child: _Step(
            number: index + 1,
            count: steps.length,
            title: title,
            // Room for Next, which stays over the bottom of the page.
            bottomPadding: index < steps.length - 1 ? 88 : 24,
            child: content,
          ),
        ),
    ];
  }
}

const _clientsUrl = 'https://console.cloud.google.com/auth/clients/create';

/// A step: how far along setup is, its title, then [child].
class _Step extends StatelessWidget {
  final int number;
  final int count;
  final String title;
  final double bottomPadding;
  final Widget child;

  const _Step({
    required this.number,
    required this.count,
    required this.title,
    required this.bottomPadding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 'Step $number of $count';
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: progress,
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: number / count,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Text(
              progress,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// The client pasted in. Saving it, or cancelling, goes back to the first
/// page.
class _PasteStep extends ConsumerWidget {
  final bool web;

  const _PasteStep({required this.web});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(oauthClientProvider);
    // Kept while it reloads after saving.
    if (!client.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    void back() => WoltModalSheet.of(context).showAtIndex(0);
    return GoogleCloudClientForm(
      initial: client.value,
      needsSecret: !web,
      signedInChannels: ref.watch(savedSignInsProvider).value?.length ?? 0,
      enabled:
          ref.watch(deletionProcessingProvider) == DeletionProcessingState.idle,
      onSave: (client) async {
        await ref.read(googleCloudClientSetupProvider.notifier).save(client);
        if (context.mounted) back();
      },
      cancelKey: GoogleCloudSetupPages.cancelKey,
      onCancel: back,
    );
  }
}

/// A step's explanation, then text to copy, then a link to where it's done.
class _StepText extends HookWidget {
  final List<String> paragraphs;
  final String? code;
  final Key? copyKey;
  final ({String label, String url}) link;

  const _StepText({
    required this.paragraphs,
    this.code,
    this.copyKey,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copied = useState(false);
    final code = this.code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(paragraph),
          ),
        if (code != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                SelectableText(
                  code,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  key: copyKey,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    copied.value = true;
                  },
                  icon: isTinyWidth(context)
                      ? null
                      : Icon(copied.value ? Icons.check : Icons.copy),
                  label: Text(copied.value ? 'Copied' : 'Copy'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        FilledButton.tonalIcon(
          onPressed: () => launchUrl(Uri.parse(link.url)),
          icon: isTinyWidth(context) ? null : const Icon(Icons.open_in_new),
          label: Text(link.label, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _TopBarTitle extends StatelessWidget {
  final String text;

  const _TopBarTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
  );
}

/// Back a step, or from the first one to the page setup was opened from.
class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8),
    child: IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => WoltModalSheet.of(context).showPrevious(),
      icon: const BackButtonIcon(),
    ),
  );
}

class _Close extends StatelessWidget {
  const _Close();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.only(end: 8),
    child: CloseButton(),
  );
}

class _Next extends StatelessWidget {
  const _Next();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
    child: FilledButton(
      key: GoogleCloudSetupPages.nextKey,
      onPressed: () => WoltModalSheet.of(context).showNext(),
      child: const Text('Next', textAlign: TextAlign.center),
    ),
  );
}
