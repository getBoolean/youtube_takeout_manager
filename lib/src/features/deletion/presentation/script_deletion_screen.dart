import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import '../application/deleted_ids_providers.dart';
import '../application/deletion_queue_notifier.dart';
import '../application/script_deletion_ids.dart';
import '../application/script_generator_service.dart';

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
  _ImportResult? _importResult;

  @override
  void dispose() {
    _resultsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentIds = ref.watch(scriptDeletionIdsProvider);
    final theme = Theme.of(context);

    if (commentIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Script Deletion')),
        body: const Center(child: Text('No comments selected.')),
      );
    }

    final takeout = ref.watch(takeoutProvider).value;
    final uncertainCount = takeout == null
        ? 0
        : takeout.liveChats
              .where(
                (c) =>
                    commentIds.contains(c.liveChatId) &&
                    c.rawText.trim().isEmpty,
              )
              .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Delete via My Activity')),
      body: Column(
        children: [
          if (uncertainCount > 0) _buildUncertainWarning(theme, uncertainCount),
          Expanded(child: _buildStepper(theme, commentIds)),
        ],
      ),
    );
  }

  Widget _buildUncertainWarning(ThemeData theme, int count) {
    final message = Intl.plural(
      count,
      one:
          '1 item may be a membership event or already-deleted message. '
          'Deletion may fail for it.',
      other:
          '$count items may be membership events or already-deleted '
          'messages. Deletion may fail for these.',
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(ThemeData theme, Set<String> commentIds) {
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
        _buildStep2CopyScript(theme, commentIds),
        _buildStep3RunScript(theme),
        _buildStep4ImportResults(theme, commentIds),
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

  Step _buildStep2CopyScript(ThemeData theme, Set<String> commentIds) {
    return Step(
      title: const Text('Copy Script'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Intl.plural(
              commentIds.length,
              one: 'This script will delete 1 item.',
              other: 'This script will delete ${commentIds.length} items.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _copyScript(commentIds),
            icon: Icon(_copied ? Icons.check : Icons.copy),
            label: Text(_copied ? 'Copied!' : 'Copy Script'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyScript(Set<String> commentIds) async {
    final script = await ScriptGeneratorService().generateDeletionScript(
      commentIds,
    );
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

  Step _buildStep4ImportResults(ThemeData theme, Set<String> commentIds) {
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
              onPressed: () => _importResults(commentIds),
              icon: const Icon(Icons.file_download),
              label: const Text('Import Results'),
            ),
          ] else ...[
            _buildResultsSummary(theme, commentIds),
          ],
        ],
      ),
    );
  }

  Future<void> _importResults(Set<String> commentIds) async {
    final text = _resultsController.text.trim();
    if (text.isEmpty) return;

    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      final succeeded = (map['succeeded'] as List).cast<String>().toSet();
      final failed = (map['failed'] as List)
          .map(
            (e) => (
              id: (e as Map<String, dynamic>)['id'] as String,
              error: e['error'] as String,
            ),
          )
          .toList();

      // Split succeeded IDs into comments vs live chats by checking
      // which set they belong to in the current takeout data.
      if (succeeded.isNotEmpty) {
        final takeout = ref.read(takeoutProvider).value;
        final commentIdSet =
            takeout?.comments.map((c) => c.commentId).toSet() ?? {};
        final liveChatIdSet =
            takeout?.liveChats.map((c) => c.liveChatId).toSet() ?? {};

        final deletedComments = succeeded.intersection(commentIdSet);
        final deletedLiveChats = succeeded.intersection(liveChatIdSet);

        if (deletedComments.isNotEmpty) {
          await ref
              .read(deletedCommentIdsProvider.notifier)
              .markDeleted(deletedComments);
        }
        if (deletedLiveChats.isNotEmpty) {
          await ref
              .read(deletedLiveChatIdsProvider.notifier)
              .markDeleted(deletedLiveChats);
        }
      }

      await ref
          .read(deletionQueueProvider.notifier)
          .recordMyActivityResults(
            deletedIds: succeeded,
            errorsById: {for (final f in failed) f.id: f.error},
          );

      setState(() {
        _importResult = _ImportResult(succeeded: succeeded, failed: failed);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid JSON: $e')));
      }
    }
  }

  Widget _buildResultsSummary(ThemeData theme, Set<String> commentIds) {
    final result = _importResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text('${result.succeeded.length} deleted'),
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
              final failedIds = result.failed.map((f) => f.id).toSet();
              ref.read(scriptDeletionIdsProvider.notifier).set(failedIds);
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

class _ImportResult {
  final Set<String> succeeded;
  final List<({String id, String error})> failed;

  const _ImportResult({required this.succeeded, required this.failed});
}
