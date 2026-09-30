import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import '../domain/oauth_client.dart';

/// Why a pasted client ID can't be used, and how to fix it.
String clientIdProblemMessage(ClientIdProblem problem) => switch (problem) {
  ClientIdProblem.missing => "Paste your client's ID from Google Cloud.",
  ClientIdProblem.notAClientId =>
    "This isn't a client ID. Copy the Client ID from your client's page in "
        'Google Cloud; it ends in .apps.googleusercontent.com.',
};

const _missingSecret =
    "Paste your client's secret. Google shows it once, when the client is "
    "created; if it's lost, add a new secret on the client's page.";

/// Where the Google Cloud client is pasted in: its ID, and on desktop and
/// mobile its secret. Problems show under their field when it's left or
/// saved, and focus moves to the first. [onSave] gets the client; while it
/// runs Save shows progress, and if it throws, why shows under Save. With
/// [onCancel], Cancel sits beside Save.
class GoogleCloudClientForm extends HookWidget {
  static const idFieldKey = ValueKey('google-cloud-client-id');
  static const secretFieldKey = ValueKey('google-cloud-client-secret');
  static const saveKey = ValueKey('google-cloud-client-save');

  /// The client already set up, to change.
  final OAuthClient? initial;

  /// Whether the client needs a secret: a Desktop app client does, a web one
  /// doesn't.
  final bool needsSecret;

  /// Channels signed in with [initial], signed out if another is saved.
  final int signedInChannels;

  /// False while the client can't change, e.g. during a deletion.
  final bool enabled;

  final Future<void> Function(OAuthClient client) onSave;
  final VoidCallback? onCancel;
  final Key? cancelKey;

  const GoogleCloudClientForm({
    super.key,
    this.initial,
    required this.needsSecret,
    this.signedInChannels = 0,
    this.enabled = true,
    required this.onSave,
    this.onCancel,
    this.cancelKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final id = useTextEditingController(text: initial?.id);
    final secret = useTextEditingController(text: initial?.secret);
    final idFocus = useFocusNode();
    final secretFocus = useFocusNode();
    final obscured = useState(true);
    final saving = useState(false);
    final failure = useState<String?>(null);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) {
        if (clientIdProblem(id.text) != null) {
          idFocus.requestFocus();
        } else {
          secretFocus.requestFocus();
        }
        return;
      }
      saving.value = true;
      failure.value = null;
      try {
        await onSave(
          OAuthClient.fromInput(
            id.text,
            secret: needsSecret ? secret.text : null,
          ),
        );
      } on Exception catch (e) {
        if (!context.mounted) return;
        final text = '$e'.replaceFirst(RegExp('^Exception: '), '');
        failure.value = "Couldn't save the client: $text";
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    final canSave = enabled && !saving.value;
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: idFieldKey,
            controller: id,
            focusNode: idFocus,
            enabled: canSave,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: needsSecret
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: (_) =>
                needsSecret ? secretFocus.requestFocus() : save(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Client ID',
              helperText: 'Ends in .apps.googleusercontent.com',
              helperMaxLines: 3,
              errorMaxLines: 4,
            ),
            validator: (value) => switch (clientIdProblem(value ?? '')) {
              final problem? => clientIdProblemMessage(problem),
              null => null,
            },
          ),
          if (needsSecret) ...[
            const SizedBox(height: 16),
            TextFormField(
              key: secretFieldKey,
              controller: secret,
              focusNode: secretFocus,
              enabled: canSave,
              obscureText: obscured.value,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => save(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Client secret',
                helperText:
                    'Google shows it once, when the client is created. Lost '
                    "it? Add a new secret on the client's page.",
                helperMaxLines: 4,
                errorMaxLines: 4,
                suffixIcon: IconButton(
                  tooltip: obscured.value ? 'Show secret' : 'Hide secret',
                  onPressed: () => obscured.value = !obscured.value,
                  icon: Icon(
                    obscured.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? _missingSecret : null,
            ),
          ],
          const SizedBox(height: 16),
          if (!enabled)
            _Note('Pause the deletion to change the client.')
          else if (initial != null && signedInChannels > 0)
            _Note(
              Intl.plural(
                signedInChannels,
                one: 'Saving a different client signs out your channel.',
                other:
                    'Saving a different client signs out your '
                    '$signedInChannels channels.',
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: saveKey,
                  onPressed: canSave ? save : null,
                  icon: saving.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : isTinyWidth(context)
                      ? null
                      : const Icon(Icons.check),
                  label: const Text('Save', textAlign: TextAlign.center),
                ),
                if (onCancel case final onCancel?)
                  TextButton(
                    key: cancelKey,
                    onPressed: saving.value ? null : onCancel,
                    child: const Text('Cancel', textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
          if (failure.value case final message?) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
