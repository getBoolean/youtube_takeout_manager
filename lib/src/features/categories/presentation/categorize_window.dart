import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../application/ai_keys.dart';
import '../application/ai_tiers.dart';
import '../application/categorization_progress.dart';
import '../application/channel_categorizer.dart';
import '../application/channel_tags.dart';
import '../application/pending_ai_work.dart';
import '../application/tag_editor.dart';
import '../domain/run_estimate.dart';
import 'ai_keys_setup.dart';
import 'category_window.dart';
import 'tag_pages.dart';

/// The ids of the Categorize window's pages, and the keys of its parts.
abstract final class CategorizeWindow {
  static const tagsId = 'categorize-tags';
  static const tagId = 'categorize-tag';
  static const runId = 'categorize-run';

  static const nextKey = ValueKey('categorize-next');
  static const runKey = ValueKey('categorize-run');
  static const stopKey = ValueKey('categorize-stop');
}

/// What the Run button can do: open the keys page, nothing, start a run,
/// stop the one going, or wait for it to stop.
enum RunState { locked, nothing, ready, running, stopping }

/// What the Run button can do, with [keys] (the services [disabled] left
/// out), what a run would do being [summary], and the run going being
/// [progress].
RunState runStateOf({
  required AiKeys keys,
  required Set<AiService> disabled,
  required AiWorkSummary? summary,
  required RunProgress progress,
}) {
  if (progress.running && progress.ai) {
    return progress.stopping ? RunState.stopping : RunState.running;
  }
  final usable = AiService.values.any(
    (service) => keys.has(service) && !disabled.contains(service),
  );
  if (!usable) return RunState.locked;
  return summary?.hasWork ?? false ? RunState.ready : RunState.nothing;
}

/// Opens the Categorize window: first the tags the user defines, to change,
/// then what a run with AI would do and cost, and Run. A run goes on when
/// the window is closed; History's banner shows it.
Future<void> showCategorizeWindow(BuildContext context) {
  // The tag being defined or changed: none for a new one.
  final editing = ValueNotifier<String?>(null);
  return WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (_) => [
      SliverWoltModalSheetPage(
        id: CategorizeWindow.tagsId,
        topBarTitle: Builder(
          builder: (context) => windowTitle(context, 'Categorize with AI'),
        ),
        isTopBarLayerAlwaysVisible: true,
        trailingNavBarWidget: const Padding(
          padding: EdgeInsetsDirectional.only(end: 8),
          child: CloseButton(),
        ),
        stickyActionBar: Builder(
          builder: (context) => _ActionBar(
            children: [
              FilledButton(
                key: CategorizeWindow.nextKey,
                onPressed: () => WoltModalSheet.of(
                  context,
                ).showPageWithId(CategorizeWindow.runId),
                child: const Text('Next', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        mainContentSliversBuilder: (context) => [
          TagsPage(
            header: const StepHeader(
              step: 1,
              steps: 2,
              title: 'Your tags',
              explanation:
                  'Define the tags you want AI to give channels. AI gives '
                  'one only where its meaning fits.',
            ),
            onOpen: (key) {
              editing.value = key;
              WoltModalSheet.of(context).showPageWithId(CategorizeWindow.tagId);
            },
          ),
          // Room for the actions, which stay over the bottom of the page.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      windowPage(
        id: CategorizeWindow.tagId,
        title: (context) => windowTitle(context, 'Tag'),
        backTo: CategorizeWindow.tagsId,
        child: ValueListenableBuilder(
          valueListenable: editing,
          builder: (context, key, _) => _EditTag(tagKey: key),
        ),
      ),
      windowPage(
        id: CategorizeWindow.runId,
        title: (context) => windowTitle(context, 'Categorize with AI'),
        backTo: CategorizeWindow.tagsId,
        stickyActionBar: Consumer(
          builder: (context, ref, _) {
            final categorizer = ref.read(channelCategorizerProvider.notifier);
            return RunActions(
              state: runStateOf(
                keys: ref.watch(aiKeysProvider).value ?? AiKeys.none,
                disabled: ref.watch(aiTierStatusProvider).disabled,
                summary: ref.watch(pendingAiWorkProvider),
                progress: ref.watch(categorizationProgressProvider),
              ),
              onRun: categorizer.run,
              onStop: categorizer.stop,
              onAddKeys: () =>
                  WoltModalSheet.of(context).showPageWithId(AiKeysPages.id),
            );
          },
        ),
        // Room for the actions, which stay over the bottom of the page.
        child: const Padding(
          padding: EdgeInsets.only(bottom: 72),
          child: RunPage(),
        ),
      ),
      AiKeysPages.page(backToId: CategorizeWindow.runId),
    ],
  ).whenComplete(editing.dispose);
}

/// The tag with the folded name [tagKey] to change, or a new one to define
/// for none; saving or deleting goes back to the tags.
class _EditTag extends ConsumerWidget {
  final String? tagKey;

  const _EditTag({required this.tagKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = tagKey == null
        ? null
        : ref.watch(tagNamesProvider.select((m) => m.value?[tagKey]));
    final editor = ref.read(tagEditorProvider.notifier);
    void back() =>
        WoltModalSheet.of(context).showPageWithId(CategorizeWindow.tagsId);
    final key = tagKey;
    return TagForm(
      // A fresh form for each tag opened.
      key: ValueKey(key),
      name: tag?.name,
      initialMeaning: tag?.meaning,
      onSave: (name, meaning) async {
        if (key == null) {
          await editor.define(name, meaning: meaning);
        } else {
          await editor.setMeaning(key, meaning);
        }
        if (context.mounted) back();
      },
      onDelete: key == null
          ? null
          : () async {
              await editor.delete(key);
              if (context.mounted) back();
            },
    );
  }
}

/// How far along a flow is, as a bar and "Step [step] of [steps]", then the
/// step's [title] and what it's for.
class StepHeader extends StatelessWidget {
  final int step;
  final int steps;
  final String title;
  final String? explanation;

  const StepHeader({
    super.key,
    required this.step,
    required this.steps,
    required this.title,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiny = isTinyWidth(context);
    final progress = 'Step $step of $steps';
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: progress,
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: step / steps,
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
          if (explanation case final explanation?) ...[
            const SizedBox(height: 8),
            Text(explanation, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// A price for what a run would cost: under a dollar, else about so many.
String _about(double dollars) =>
    dollars < 1 ? r'under $1' : 'about \$${dollars.ceil()}';

/// What a run with AI would do, in numbers, the services it would ask and
/// roughly what each would cost; while one goes, how far along it is and
/// what Claude has cost so far.
class RunPage extends ConsumerWidget {
  const RunPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tiny = isTinyWidth(context);
    final summary = ref.watch(pendingAiWorkProvider);
    final keys = ref.watch(aiKeysProvider).value ?? AiKeys.none;
    final progress = ref.watch(categorizationProgressProvider);
    final usage = ref.watch(claudeUsageProvider);
    final count = NumberFormat.decimalPattern();
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final running = progress.running && progress.ai;
    final spent = usage.input + usage.output > 0
        ? claudeDollars(usage.input, usage.output)
        : null;

    final List<Widget> lines;
    if (running) {
      lines = [
        Text(
          progress.stopping
              ? 'Stopping once the answers already asked for come…'
              : 'Categorizing with AI: ${count.format(progress.done)} of '
                    '${formatCount(progress.total, 'channel')}',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.total == 0 ? null : progress.done / progress.total,
          borderRadius: BorderRadius.circular(4),
        ),
      ];
    } else if (summary == null) {
      lines = [
        Text('Working out what a run would do…', style: muted),
        const SizedBox(height: 8),
        const LinearProgressIndicator(),
      ];
    } else if (!summary.hasWork) {
      lines = [Text('Nothing to do: AI has seen every channel.', style: muted)];
    } else {
      String? line(int n, String what) =>
          n == 0 ? null : '${count.format(n)} $what';
      final cost = estimateRunCost(summary, keys: keys, model: anthropicModel);
      lines = [
        for (final text in [
          line(
            summary.categorize,
            summary.categorize == 1
                ? 'channel to categorize'
                : 'channels to categorize',
          ),
          line(summary.redo, 'to categorize again with updated prompts'),
          line(summary.tags, 'to tag'),
          line(summary.checks, 'to check for your tags'),
        ])
          if (text != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(text, style: theme.textTheme.bodyLarge),
            ),
        if (summary.uncategorized > 0)
          Text(
            '${count.format(summary.uncategorized)} without a category, so '
            'they get no tags',
            style: muted,
          ),
        const SizedBox(height: 16),
        if (keys.hasJev) Text('Jev: ${_about(cost.jevDollars)}'),
        if (keys.hasClaude)
          Text(switch (cost.claudeDollars) {
            final dollars? =>
              'Claude: ${dollars < 1 ? r'under $1' : 'up to \$${dollars.ceil()}'}'
                  ' if every channel needs it; usually much less',
            null =>
              'Claude: up to ${formatCount(cost.claudeRequests, 'request')}',
          }),
        if (!keys.hasAny)
          Text('Add an API key for Jev or Claude to run this.', style: muted),
      ];
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 0, tiny ? 8 : 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(step: 2, steps: 2, title: 'Run'),
          const SizedBox(height: 8),
          ...lines,
          if (spent != null) ...[
            const SizedBox(height: 8),
            Text(
              'Claude so far: about \$${spent.toStringAsFixed(2)}',
              style: muted,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'You can close this window: History shows how it goes.',
            style: muted,
          ),
        ],
      ),
    );
  }
}

/// The Run page's actions: Run, with the magic wand, muted with a lock
/// without keys ([onAddKeys]), off with nothing to do; Stop while a run
/// goes.
class RunActions extends StatelessWidget {
  final RunState state;
  final VoidCallback? onRun;
  final VoidCallback? onStop;
  final VoidCallback? onAddKeys;

  const RunActions({
    super.key,
    required this.state,
    this.onRun,
    this.onStop,
    this.onAddKeys,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tiny = isTinyWidth(context);
    const wand = Icon(Icons.auto_fix_high);
    return _ActionBar(
      children: [
        switch (state) {
          RunState.locked => TextButton.icon(
            key: CategorizeWindow.runKey,
            onPressed: onAddKeys,
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Run', textAlign: TextAlign.center),
          ),
          RunState.nothing || RunState.ready => FilledButton.icon(
            key: CategorizeWindow.runKey,
            onPressed: state == RunState.ready ? onRun : null,
            icon: tiny ? null : wand,
            label: const Text('Run', textAlign: TextAlign.center),
          ),
          RunState.running => OutlinedButton.icon(
            key: CategorizeWindow.stopKey,
            onPressed: onStop,
            icon: tiny ? null : const Icon(Icons.stop_circle_outlined),
            label: const Text('Stop', textAlign: TextAlign.center),
          ),
          RunState.stopping => OutlinedButton(
            key: CategorizeWindow.stopKey,
            onPressed: null,
            child: const Text('Stopping…', textAlign: TextAlign.center),
          ),
        },
      ],
    );
  }
}

/// A window page's buttons, at its bottom, at the end.
class _ActionBar extends StatelessWidget {
  final List<Widget> children;

  const _ActionBar({required this.children});

  @override
  Widget build(BuildContext context) {
    final tiny = isTinyWidth(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 16),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: children,
      ),
    );
  }
}
