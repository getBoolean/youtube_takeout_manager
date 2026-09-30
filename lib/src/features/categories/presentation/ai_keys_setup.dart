import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import '../application/ai_keys.dart';
import '../data/ai_keys_repository.dart';

/// What [service] is called on screen.
String aiServiceName(AiService service) => switch (service) {
  AiService.jev => 'Jev by TypeSafe',
  AiService.claude => 'Claude by Anthropic',
};

const _keyPages = {
  AiService.jev: 'https://console.typesafe.ai',
  AiService.claude: 'https://console.anthropic.com/settings/keys',
};

/// Opens the AI keys page of the modal [context] is in.
void showAiKeysSetup(BuildContext context) =>
    WoltModalSheet.of(context).showPageWithId(AiKeysPages.id);

/// The AI keys page, for a Wolt modal whose first page opened it: saving
/// the keys, or cancelling, goes back to that first page.
abstract final class AiKeysPages {
  static const id = 'ai-keys';

  static SliverWoltModalSheetPage page() => WoltModalSheetPage(
    id: id,
    topBarTitle: const _TopBarTitle('AI keys'),
    isTopBarLayerAlwaysVisible: true,
    leadingNavBarWidget: const _Back(),
    trailingNavBarWidget: const _Close(),
    child: const Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: _AiKeysPageBody(),
    ),
  );
}

/// The AI categories setting: which AI services have keys, and adding or
/// changing the ones the build has none for. Nothing when the build has
/// every key.
class AiKeysSection extends ConsumerWidget {
  static const setUpKey = ValueKey('ai-keys-set-up');
  static const changeKey = ValueKey('ai-keys-change');

  const AiKeysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(aiKeysRepositoryProvider);
    if (AiService.values.every(repository.isBuiltIn)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final keys = ref.watch(aiKeysProvider).value ?? AiKeys.none;
    final tiny = isTinyWidth(context);
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI categories', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          keys.hasAny
              ? 'AI checks the categories YouTube gives channels, and names '
                    'the ones it has none for.'
              : 'Add an API key for Jev or Claude, and AI checks the '
                    'categories YouTube gives channels and names the ones it '
                    "has none for. Without one, categories come from YouTube's "
                    'topics alone.',
          style: hint,
        ),
        const SizedBox(height: 8),
        if (keys.hasAny) ...[
          for (final service in AiService.values)
            _ServiceStatus(
              service: service,
              status: repository.isBuiltIn(service)
                  ? 'Built into this app'
                  : keys.has(service)
                  ? 'Key added'
                  : 'No key',
              on: keys.has(service),
            ),
          TextButton.icon(
            key: changeKey,
            onPressed: () => showAiKeysSetup(context),
            icon: tiny ? null : const Icon(Icons.edit_outlined),
            label: const Text('Change', textAlign: TextAlign.center),
          ),
        ] else
          FilledButton.tonalIcon(
            key: setUpKey,
            onPressed: () => showAiKeysSetup(context),
            icon: tiny ? null : const Icon(Icons.auto_awesome_outlined),
            label: const Text('Add keys', textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

/// One AI service and whether it has a key, as a line of the section.
class _ServiceStatus extends StatelessWidget {
  final AiService service;
  final String status;
  final bool on;

  const _ServiceStatus({
    required this.service,
    required this.status,
    required this.on,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isTinyWidth(context)) ...[
            Icon(
              on ? Icons.check_circle_outline : Icons.remove_circle_outline,
              size: 18,
              color: on ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: aiServiceName(service),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · $status'),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// The keys to enter, once they've loaded. Saving, or cancelling, goes back
/// to the modal's first page.
class _AiKeysPageBody extends ConsumerWidget {
  const _AiKeysPageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(aiKeysProvider);
    // Kept while they reload after saving.
    if (!keys.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final repository = ref.watch(aiKeysRepositoryProvider);
    void back() => WoltModalSheet.of(context).showAtIndex(0);
    return AiKeysForm(
      key: ValueKey(keys.value),
      initial: keys.requireValue,
      builtIn: {
        for (final service in AiService.values)
          if (repository.isBuiltIn(service)) service,
      },
      onSave: (keys) async {
        await ref.read(aiKeysSetupProvider.notifier).save(keys);
        if (context.mounted) back();
      },
      onCancel: back,
    );
  }
}

/// Where the AI services' API keys are entered, hidden until shown, with a
/// link to where each is made. A service whose key is [builtIn] has no field.
/// [onSave] gets every field's text, blank for none; while it runs Save
/// shows progress, and if it throws, why shows under Save.
class AiKeysForm extends HookWidget {
  static ValueKey<String> fieldKey(AiService service) =>
      ValueKey('ai-key-field-${service.name}');
  static ValueKey<String> builtInKey(AiService service) =>
      ValueKey('ai-key-built-in-${service.name}');
  static const saveKey = ValueKey('ai-keys-save');
  static const cancelKey = ValueKey('ai-keys-cancel');
  static const failureKey = ValueKey('ai-keys-failure');

  final AiKeys initial;
  final Set<AiService> builtIn;
  final Future<void> Function(Map<AiService, String> keys) onSave;
  final VoidCallback? onCancel;

  const AiKeysForm({
    super.key,
    required this.initial,
    this.builtIn = const {},
    required this.onSave,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jev = useTextEditingController(
      text: builtIn.contains(AiService.jev) ? '' : initial.typesafe,
    );
    final claude = useTextEditingController(
      text: builtIn.contains(AiService.claude) ? '' : initial.anthropic,
    );
    final controllers = {AiService.jev: jev, AiService.claude: claude};
    final saving = useState(false);
    final failure = useState<String?>(null);

    Future<void> save() async {
      saving.value = true;
      failure.value = null;
      try {
        await onSave({
          for (final MapEntry(key: service, value: controller)
              in controllers.entries)
            if (!builtIn.contains(service)) service: controller.text,
        });
      } on Exception catch (e) {
        if (!context.mounted) return;
        final text = '$e'.replaceFirst(RegExp('^Exception: '), '');
        failure.value = "Couldn't save the keys: $text";
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AI checks the category YouTube gives each channel, and names the '
          'ones YouTube has none for. Jev checks and picks from known '
          "categories for a fraction of a cent; Claude names what Jev can't "
          'settle. Add a key for either, or both.',
        ),
        const SizedBox(height: 8),
        Text(
          'To pick categories, channel names and descriptions, and the titles '
          'of videos you watched from them, are sent to the services you add '
          "keys for. Each bills your own account. Keys stay in this device's "
          'secure storage.',
          style: hint,
        ),
        for (final service in AiService.values) ...[
          const SizedBox(height: 20),
          if (builtIn.contains(service))
            _BuiltIn(key: builtInKey(service), service: service)
          else
            _KeyField(
              key: fieldKey(service),
              service: service,
              controller: controllers[service]!,
              enabled: !saving.value,
              onSubmitted: save,
            ),
        ],
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: saveKey,
                onPressed: saving.value ? null : save,
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
              key: failureKey,
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One service's key, hidden until shown, and a link to where it's made.
class _KeyField extends HookWidget {
  final AiService service;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  const _KeyField({
    super.key,
    required this.service,
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final obscured = useState(true);
    final name = aiServiceName(service);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscured.value,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: '$name API key',
            helperText: 'Leave it blank to go without $name.',
            helperMaxLines: 3,
            suffixIcon: IconButton(
              tooltip: obscured.value ? 'Show key' : 'Hide key',
              onPressed: () => obscured.value = !obscured.value,
              icon: Icon(
                obscured.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse(_keyPages[service]!)),
          icon: isTinyWidth(context) ? null : const Icon(Icons.open_in_new),
          label: Text('Get a $name key', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

/// A service whose key came with the build, so there's nothing to enter.
class _BuiltIn extends StatelessWidget {
  final AiService service;

  const _BuiltIn({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isTinyWidth(context)) ...[
          Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(aiServiceName(service), style: theme.textTheme.titleSmall),
              Text(
                'Its key is built into this app.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopBarTitle extends StatelessWidget {
  final String text;

  const _TopBarTitle(this.text);

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    ),
  );
}

/// Back to the page the keys were opened from.
class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8),
    child: IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => WoltModalSheet.of(context).showAtIndex(0),
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
