import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/deletion_service.dart';
import '../application/script_deletion_ids.dart';
import '../application/script_generator_service.dart';
import '../domain/deletion_targets.dart';
import '../domain/my_activity_results.dart';
import 'possible_membership_events_notice.dart';

@RoutePage()
class ScriptDeletionScreen extends ConsumerStatefulWidget {
  const ScriptDeletionScreen({super.key});

  @override
  ConsumerState<ScriptDeletionScreen> createState() =>
      _ScriptDeletionScreenState();
}

class _ScriptDeletionScreenState extends ConsumerState<ScriptDeletionScreen> {
  static const _myActivityUrl =
      'https://myactivity.google.com/page?hl=en&page=youtube_comments';

  int _currentStep = 0;
  bool _copied = false;
  final _resultsController = TextEditingController();
  MyActivityResults? _importResult;

  @override
  void dispose() {
    _resultsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targets = ref.watch(scriptDeletionIdsProvider);
    final theme = Theme.of(context);

    if (targets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Script Deletion')),
        body: const Center(child: Text('No comments selected.')),
      );
    }

    final uncertainCount = ref.watch(scriptPossibleMembershipEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delete via My Activity')),
      body: Column(
        children: [
          if (uncertainCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: PossibleMembershipEventsNotice(count: uncertainCount),
            ),
          Expanded(child: _buildStepper(theme, targets)),
        ],
      ),
    );
  }

  Widget _buildStepper(ThemeData theme, DeletionTargets targets) {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _currentStep < 3
          ? () => setState(() => _currentStep++)
          : null,
      onStepCancel: _currentStep > 0
          ? () => setState(() => _currentStep--)
          : null,
      controlsBuilder: (context, details) {
        if (_currentStep == 3 && _importResult != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FilledButton(
              onPressed: () {
                ref.read(scriptDeletionIdsProvider.notifier).clear();
                context.router.maybePop();
              },
              child: const Text('Done'),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              if (details.onStepContinue != null)
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: const Text('Next'),
                ),
              if (details.onStepCancel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              ],
            ],
          ),
        );
      },
      steps: [
        _buildStep1OpenActivity(theme),
        _buildStep2CopyScript(theme, targets),
        _buildStep3RunScript(theme),
        _buildStep4ImportResults(theme, targets),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Open My Activity
  // ---------------------------------------------------------------------------

  Step _buildStep1OpenActivity(ThemeData theme) {
    return Step(
      title: const Text('Open My Activity'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sign in and open your YouTube Comments activity page.'),
          const SizedBox(height: 12),
          SelectableText(
            _myActivityUrl,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => launchUrl(Uri.parse(_myActivityUrl)),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Copy Script
  // ---------------------------------------------------------------------------

  Step _buildStep2CopyScript(ThemeData theme, DeletionTargets targets) {
    return Step(
      title: const Text('Copy Script'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Intl.plural(
              targets.count,
              one: 'This script will delete 1 item.',
              other: 'This script will delete ${targets.count} items.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _copyScript(targets),
            icon: Icon(_copied ? Icons.check : Icons.copy),
            label: Text(_copied ? 'Copied!' : 'Copy Script'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyScript(DeletionTargets targets) async {
    final script = await ref
        .read(scriptGeneratorServiceProvider)
        .generateDeletionScript(targets.allIds);
    await Clipboard.setData(ClipboardData(text: script));
    setState(() => _copied = true);
  }

  // ---------------------------------------------------------------------------
  // Step 3: Run Script
  // ---------------------------------------------------------------------------

  Step _buildStep3RunScript(ThemeData theme) {
    return Step(
      title: const Text('Run Script'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('In the browser on the My Activity page:'),
          SizedBox(height: 8),
          Text('1. Press F12 (or Ctrl+Shift+J) to open DevTools'),
          Text('2. Go to the Console tab'),
          Text('3. Paste the script and press Enter'),
          Text('4. Wait for it to finish — progress is logged in the console'),
          Text('5. Results are automatically copied to your clipboard'),
          SizedBox(height: 8),
          Text(
            'When the script finishes, proceed to the next step to import the results.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: Import Results
  // ---------------------------------------------------------------------------

  Step _buildStep4ImportResults(ThemeData theme, DeletionTargets targets) {
    return Step(
      title: const Text('Import Results'),
      isActive: _currentStep >= 3,
      state: _importResult != null ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_importResult == null) ...[
            const Text('Paste the JSON results from your clipboard:'),
            const SizedBox(height: 12),
            TextField(
              controller: _resultsController,
              maxLines: 6,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"succeeded":[...],"failed":[...]}',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _importResults(targets),
              icon: const Icon(Icons.file_download),
              label: const Text('Import Results'),
            ),
          ] else ...[
            _buildResultsSummary(theme),
          ],
        ],
      ),
    );
  }

  Future<void> _importResults(DeletionTargets targets) async {
    final text = _resultsController.text.trim();
    if (text.isEmpty) return;

    switch (parseMyActivityResults(text)) {
      case MalformedMyActivityResults(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid JSON: $error')));
      case final MyActivityResults results:
        try {
          await ref
              .read(deletionServiceProvider.notifier)
              .recordMyActivityResults(targets, results);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Couldn't save the results: $e")),
          );
          return;
        }
        if (!mounted) return;
        setState(() => _importResult = results);
    }
  }

  Widget _buildResultsSummary(ThemeData theme) {
    final result = _importResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text('${result.deleted.length} deleted'),
          ],
        ),
        if (result.failed.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text('${result.failed.length} failed'),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: result.failed.length,
              itemBuilder: (context, index) {
                final f = result.failed[index];
                return Text(
                  '${f.id}: ${f.error}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Retry with just the failed IDs.
              ref
                  .read(scriptDeletionIdsProvider.notifier)
                  .keepOnly(result.errorsById.keys.toSet());
              setState(() {
                _currentStep = 1;
                _copied = false;
                _importResult = null;
                _resultsController.clear();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Failed'),
          ),
        ],
      ],
    );
  }
}
