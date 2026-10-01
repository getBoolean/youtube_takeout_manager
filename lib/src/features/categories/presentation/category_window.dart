import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../application/ai_keys.dart';
import '../application/ai_tiers.dart';
import '../application/categorizing_channels.dart';
import '../application/category_editor.dart';
import '../application/channel_categories.dart';
import '../application/channel_categorizer.dart';
import '../application/channel_tags.dart';
import '../domain/category_path.dart';
import '../domain/channel_category.dart';
import '../domain/name_key.dart';
import '../domain/sub_category.dart';
import '../domain/tag_name.dart';
import '../domain/youtube_topics.dart';
import 'ai_keys_setup.dart';
import 'category_change_pages.dart';
import 'category_colors.dart';

/// Whether AI can be asked for another category in the window, and how.
enum AskAi {
  /// Not offered: AI or the user chose the category.
  hidden,
  available,

  /// Offered, but there's no key: it opens where keys are added.
  locked,

  /// Offered, but categorizing is asking about the channel now.
  busy,
}

/// How Ask AI is offered for a channel with [category] (none yet when
/// null): for YouTube's categories, Uncategorized, and channels not
/// categorized yet; [canAskAi] with a key; not while categorizing is
/// [busy] with the channel.
AskAi askAiFor(
  ChannelCategory? category, {
  required bool canAskAi,
  required bool busy,
}) {
  final offered =
      category == null ||
      category.path == null ||
      category.source == CategorySource.youtube;
  if (!offered) return AskAi.hidden;
  if (busy) return AskAi.busy;
  return canAskAi ? AskAi.available : AskAi.locked;
}

/// The ids of the category window's pages, and the keys of its parts.
abstract final class CategoryWindow {
  static const mainId = 'category-main';
  static const askId = 'category-ask';
  static const changeId = 'category-change';
  static const newSubId = 'category-new-sub';
  static const emojiId = 'category-emoji';
  static const addTagId = 'category-add-tag';

  static const youtubeSourceKey = ValueKey('category-source-youtube');
  static const aiSourceKey = ValueKey('category-source-ai');
  static const useYouTubeKey = ValueKey('category-use-youtube');
  static const changeKey = ValueKey('category-change');
  static const askAiKey = ValueKey('category-ask-ai');
  static const addTagKey = ValueKey('category-add-tag');

  static ValueKey<String> tagKey(String tag) => ValueKey('category-tag-$tag');
}

/// The title of one of the window's pages.
Widget windowTitle(BuildContext context, String text) => Semantics(
  header: true,
  child: Text(
    text,
    style: Theme.of(context).textTheme.titleMedium,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
);

const _close = Padding(
  padding: EdgeInsetsDirectional.only(end: 8),
  child: CloseButton(),
);

/// Back to the page [id].
Widget windowBack(String id) => Padding(
  padding: const EdgeInsetsDirectional.only(start: 8),
  child: Builder(
    builder: (context) => IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => WoltModalSheet.of(context).showPageWithId(id),
      icon: const BackButtonIcon(),
    ),
  ),
);

/// A page of the window: [title], back to [backTo] when given, closing,
/// holding [child].
WoltModalSheetPage windowPage({
  required String id,
  required Widget Function(BuildContext context) title,
  String? backTo,
  Widget? stickyActionBar,
  required Widget child,
}) => WoltModalSheetPage(
  id: id,
  topBarTitle: Builder(builder: title),
  isTopBarLayerAlwaysVisible: true,
  leadingNavBarWidget: backTo == null ? null : windowBack(backTo),
  trailingNavBarWidget: _close,
  stickyActionBar: stickyActionBar,
  child: child,
);

/// A page of the window built of [slivers], as [windowPage] is.
SliverWoltModalSheetPage windowSliverPage({
  required String id,
  required Widget Function(BuildContext context) title,
  String? backTo,
  required List<Widget> slivers,
}) => SliverWoltModalSheetPage(
  id: id,
  topBarTitle: Builder(builder: title),
  isTopBarLayerAlwaysVisible: true,
  leadingNavBarWidget: backTo == null ? null : windowBack(backTo),
  trailingNavBarWidget: _close,
  mainContentSliversBuilder: (_) => slivers,
);

/// Opens [channel]'s category window: its category, where it came from,
/// YouTube's category to switch to when AI chose another, its tags to
/// change, and, at the bottom, changing the category or asking AI for
/// another. What the user decides is kept as they decide it; the window
/// stays open until closed.
Future<void> showCategoryWindow(
  BuildContext context, {
  required HistoryChannel channel,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final categorizer = container.read(channelCategorizerProvider.notifier);
  final editor = container.read(categoryEditorProvider.notifier);
  // One request however many times the modal builds the page showing it
  // (it measures pages offstage): each ask is paid for.
  final asking = ValueNotifier<Future<ChannelCategory>?>(null);
  final draft = NewSubCategoryDraft();
  void ask() => asking.value = categorizer.suggest(channel)
    // Shown on the page; not an unhandled error if it closed first.
    ..ignore();
  return WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (_) => [
      windowPage(
        id: CategoryWindow.mainId,
        title: (context) => windowTitle(context, channel.title),
        stickyActionBar: Consumer(
          builder: (context, ref, _) {
            final category = ref.watch(
              channelCategoriesProvider.select((m) => m.value?[channel.key]),
            );
            // Rebuilt as keys are added or turned off.
            ref
              ..watch(aiKeysProvider)
              ..watch(aiTierStatusProvider);
            final busy = ref.watch(
              categorizingChannelsProvider.select(
                (keys) => keys.contains(channel.key),
              ),
            );
            final modal = WoltModalSheet.of(context);
            return CategoryWindowActions(
              askAi: askAiFor(
                category,
                canAskAi: ref
                    .read(channelCategorizerProvider.notifier)
                    .canAskAi,
                busy: busy,
              ),
              onChange: () => modal.showPageWithId(CategoryWindow.changeId),
              onAskAi: () {
                ask();
                modal.showPageWithId(CategoryWindow.askId);
              },
              onAddKeys: () => modal.showPageWithId(AiKeysPages.id),
            );
          },
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final category = ref.watch(
              channelCategoriesProvider.select((m) => m.value?[channel.key]),
            );
            final topics =
                ref.watch(
                  channelDetailsProvider.select(
                    (m) => m.value?[channel.channelId]?.topicUrls,
                  ),
                ) ??
                const <String>[];
            final youtube = youtubeCandidates(topics).firstOrNull;
            return CategoryWindowMain(
              category: category,
              topicLabels: [for (final url in topics) topicLabel(url)],
              youtube: youtube,
              signedIn: ref.watch(readSessionChannelIdProvider) != null,
              emoji: ref.watch(categoryEmojiOfProvider)(category?.path),
              aiMade: _aiMade(
                ref.watch(customCategoriesProvider).value ?? const {},
                ref.watch(tagNamesProvider).value ?? const {},
              ),
              onUseYouTube: youtube == null
                  ? null
                  : () => editor.useYouTube(channel, youtube),
              onRemoveTag: (tag) => editor.setTags(channel, [
                for (final kept in category?.tags ?? const <String>[])
                  if (kept != tag) kept,
              ]),
              onAddTag: () => WoltModalSheet.of(
                context,
              ).showPageWithId(CategoryWindow.addTagId),
            );
          },
        ),
      ),
      windowPage(
        id: CategoryWindow.askId,
        title: (context) => windowTitle(context, 'Ask AI'),
        backTo: CategoryWindow.mainId,
        child: CategoryAskPage(
          asking: asking,
          onRetry: ask,
          onAccept: (suggestion) => editor.accept(channel, suggestion),
          onKeep: () => editor.deny(channel),
        ),
      ),
      ...categoryChangePages(channel, draft),
      AiKeysPages.page(),
    ],
  ).whenComplete(() {
    asking.dispose();
    draft.dispose();
  });
}

/// Whether a sub-category or tag name was made by AI: [custom]'s records
/// and [tags]' say so. YouTube's are neither.
typedef AiMade = ({
  bool Function(CategoryPath path) path,
  bool Function(String tag) tag,
});

AiMade _aiMade(
  Map<String, List<SubCategory>> custom,
  Map<String, TagName> tags,
) => (
  path: (path) {
    final child = path.child;
    if (child == null) return false;
    final key = nameKey(child);
    for (final sub in custom[path.parent] ?? const <SubCategory>[]) {
      if (nameKey(sub.name) == key) return sub.origin == NameOrigin.ai;
    }
    return false;
  },
  tag: (tag) => tags[nameKey(tag)]?.origin == NameOrigin.ai,
);

AiMade _noneAiMade() => (path: (_) => false, tag: (_) => false);

/// The window's bottom bar: changing the category, and asking AI for
/// another, as [askAi] says.
class CategoryWindowActions extends StatelessWidget {
  final AskAi askAi;
  final VoidCallback onChange;
  final VoidCallback? onAskAi;
  final VoidCallback? onAddKeys;

  const CategoryWindowActions({
    super.key,
    required this.askAi,
    required this.onChange,
    this.onAskAi,
    this.onAddKeys,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tiny = isTinyWidth(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 16),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: CategoryWindow.changeKey,
            onPressed: onChange,
            icon: tiny ? null : const Icon(Icons.edit_outlined),
            label: const Text('Change category', textAlign: TextAlign.center),
          ),
          switch (askAi) {
            AskAi.hidden => const SizedBox.shrink(),
            AskAi.available => FilledButton.tonalIcon(
              key: CategoryWindow.askAiKey,
              onPressed: onAskAi,
              icon: tiny ? null : const AiMark(size: 18),
              label: const Text('Ask AI', textAlign: TextAlign.center),
            ),
            AskAi.busy => FilledButton.tonalIcon(
              key: CategoryWindow.askAiKey,
              onPressed: null,
              icon: tiny ? null : const AiMark(size: 18),
              label: const Text(
                'Categorizing this channel…',
                textAlign: TextAlign.center,
              ),
            ),
            AskAi.locked => TextButton.icon(
              key: CategoryWindow.askAiKey,
              onPressed: onAddKeys,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
              ),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Ask AI', textAlign: TextAlign.center),
            ),
          },
        ],
      ),
    );
  }
}

/// A channel's category, large, with its emoji and colour, where it came
/// from, YouTube's category when AI chose another, and its tags.
class CategoryWindowMain extends StatelessWidget {
  final ChannelCategory? category;

  /// The topics YouTube gives the channel, by name.
  final List<String> topicLabels;

  /// The category those topics give, if any.
  final CategoryPath? youtube;

  /// Whether YouTube's topics can be asked for: signed out, they can't.
  final bool signedIn;

  /// The category's emoji.
  final String emoji;

  final AiMade aiMade;
  final VoidCallback? onUseYouTube;
  final ValueChanged<String>? onRemoveTag;
  final VoidCallback? onAddTag;

  CategoryWindowMain({
    super.key,
    required this.category,
    this.topicLabels = const [],
    this.youtube,
    this.signedIn = true,
    required this.emoji,
    AiMade? aiMade,
    this.onUseYouTube,
    this.onRemoveTag,
    this.onAddTag,
  }) : aiMade = aiMade ?? _noneAiMade();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final category = this.category;
    final path = category?.path;
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final youtube = this.youtube;
    final offerYouTube =
        (category?.isAi ?? false) && youtube != null && youtube != path;
    final tags = category?.tags ?? const <String>[];

    return Padding(
      // Room for the bar pinned at the bottom.
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!tiny) ...[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: categoryTint(path?.parent, scheme),
                  ),
                  child: Text(emoji, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(width: 12),
              ],
              if (category?.isAi ?? false) ...[
                AiMark(size: 22, color: scheme.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  [if (tiny) emoji, path?.label ?? 'Uncategorized'].join(' '),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (category == null) ...[
            Text('Not categorized yet.', style: hint),
            if (topicLabels.isEmpty && !signedIn) ...[
              const SizedBox(height: 8),
              Text(_signInForTopics, style: hint),
            ],
          ] else
            _Explanation(
              category: category,
              topicLabels: topicLabels,
              signedIn: signedIn,
            ),
          if (offerYouTube) ...[
            const SizedBox(height: 16),
            Text(
              "YouTube's topics say ${youtube.label}.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonal(
                key: CategoryWindow.useYouTubeKey,
                onPressed: onUseYouTube,
                child: const Text(
                  "Use YouTube's category",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text('Tags', style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 8),
          if (tags.isEmpty)
            Text('No tags yet.', style: hint)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  InputChip(
                    key: CategoryWindow.tagKey(tag),
                    avatar: aiMade.tag(tag) ? const AiMark(size: 16) : null,
                    label: Text(tag, overflow: TextOverflow.ellipsis),
                    deleteButtonTooltipMessage: 'Remove $tag',
                    onDeleted: onRemoveTag == null
                        ? null
                        : () => onRemoveTag!(tag),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: CategoryWindow.addTagKey,
              onPressed: tags.length >= maxTags ? null : onAddTag,
              icon: const Icon(Icons.add),
              label: const Text('Add tag', textAlign: TextAlign.center),
            ),
          ),
          if (tags.length >= maxTags)
            Text(
              'Up to $maxTags tags; remove one to add another.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

const _signInForTopics = "Sign in to get YouTube's topics for this channel.";

/// What AI suggests instead, as [asking] answers: a progress bar while it's
/// asked, then the suggestion and its tags, to use ([onAccept]) or not
/// ([onKeep]), which goes back to the window; a failure says why in place,
/// to [onRetry]. The answer, or the failure, is announced when it comes.
class CategoryAskPage extends StatefulWidget {
  static const progressKey = ValueKey('category-ask-progress');
  static const acceptKey = ValueKey('category-ask-accept');
  static const denyKey = ValueKey('category-ask-deny');
  static const retryKey = ValueKey('category-ask-retry');
  static const failureKey = ValueKey('category-ask-failure');

  final ValueListenable<Future<ChannelCategory>?> asking;
  final VoidCallback onRetry;
  final Future<void> Function(ChannelCategory suggestion)? onAccept;
  final Future<void> Function()? onKeep;

  const CategoryAskPage({
    super.key,
    required this.asking,
    required this.onRetry,
    this.onAccept,
    this.onKeep,
  });

  @override
  State<CategoryAskPage> createState() => _CategoryAskPageState();
}

class _CategoryAskPageState extends State<CategoryAskPage> {
  /// The requests announced, so each is announced once, however many
  /// copies of the page the modal builds to measure it.
  static final _told = Expando<bool>();

  /// The request this page listens to.
  Future<ChannelCategory>? _announced;

  @override
  void initState() {
    super.initState();
    widget.asking.addListener(_listen);
    _listen();
  }

  @override
  void didUpdateWidget(CategoryAskPage old) {
    super.didUpdateWidget(old);
    if (old.asking != widget.asking) {
      old.asking.removeListener(_listen);
      widget.asking.addListener(_listen);
      _listen();
    }
  }

  @override
  void dispose() {
    widget.asking.removeListener(_listen);
    super.dispose();
  }

  /// Announces the answer to the newest request when it comes.
  void _listen() {
    final request = widget.asking.value;
    if (request == null || identical(request, _announced)) return;
    _announced = request;
    request.then(
      (suggestion) => _announce(
        'AI suggests ${suggestion.path?.label ?? 'Uncategorized'}.',
      ),
      onError: (Object error) => _announce(_failureText(error)),
    );
  }

  void _announce(String message) {
    final request = _announced;
    if (request == null ||
        !mounted ||
        !identical(widget.asking.value, request) ||
        (_told[request] ?? false)) {
      return;
    }
    _told[request] = true;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: widget.asking,
    builder: (context, request, _) => FutureBuilder(
      future: request,
      builder: (context, answer) => _answer(context, answer),
    ),
  );

  /// Why AI couldn't be asked, and when to try again if the service said.
  static String _failureText(Object? error) {
    if (error is! AiTierFailure) return "AI couldn't be asked: $error";
    final failure = error.failure;
    final resumeAt = resumeAtOf(failure);
    return [
      "AI couldn't be asked: ${failure.message}",
      if (resumeAt != null) 'Try again after ${timeOfDay(resumeAt)}.',
    ].join(' ');
  }

  Future<void> _then(Future<void>? decide) async {
    final modal = WoltModalSheet.of(context);
    await decide;
    modal.showPageWithId(CategoryWindow.mainId);
  }

  Widget _answer(BuildContext context, AsyncSnapshot<ChannelCategory> answer) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final suggestion = answer.data;

    final Widget body;
    if (answer.connectionState != ConnectionState.done) {
      body = Column(
        key: CategoryAskPage.progressKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Asking AI for another category…', style: hint),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      );
    } else if (answer.hasError || suggestion == null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            key: CategoryAskPage.failureKey,
            _failureText(answer.error),
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              key: CategoryAskPage.retryKey,
              onPressed: widget.onRetry,
              icon: tiny ? null : const Icon(Icons.refresh),
              label: const Text('Try again', textAlign: TextAlign.center),
            ),
          ),
        ],
      );
    } else {
      final confidence = suggestion.confidence;
      final reason = suggestion.reason;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AiMark(size: 22, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion.path?.label ?? 'Uncategorized',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: 8),
                    Text(reason, style: hint),
                  ] else if (confidence != null) ...[
                    const SizedBox(height: 8),
                    Text('Jev is ${_percent(confidence)} sure.', style: hint),
                  ],
                  if (suggestion.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tags: ${suggestion.tags.join(', ')}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: CategoryAskPage.denyKey,
                onPressed: () => _then(widget.onKeep?.call()),
                child: const Text('Keep current', textAlign: TextAlign.center),
              ),
              FilledButton(
                key: CategoryAskPage.acceptKey,
                onPressed: () => _then(widget.onAccept?.call(suggestion)),
                child: const Text('Use this', textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 24),
      child: body,
    );
  }
}

String _percent(double odds) => '${(odds * 100).round()}%';

/// Where [category] came from: YouTube's topics, and how sure Jev was of
/// them; which AI chose it, how sure, and what came next; or the user; and
/// what the user decided about it.
class _Explanation extends StatelessWidget {
  final ChannelCategory category;
  final List<String> topicLabels;
  final bool signedIn;

  const _Explanation({
    required this.category,
    required this.topicLabels,
    required this.signedIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final category = this.category;
    final confidence = category.confidence;
    final jevAgreed = category.jevAgreed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (category.source) {
          CategorySource.claude => Text(
            key: CategoryWindow.aiSourceKey,
            switch (category.reason) {
              final reason? => 'Chosen by Claude: $reason',
              null => 'Chosen by Claude.',
            },
            style: hint,
          ),
          CategorySource.jev => Text(
            key: CategoryWindow.aiSourceKey,
            confidence == null
                ? 'Chosen by Jev from the known categories.'
                : 'Chosen by Jev from the known categories, '
                      '${_percent(confidence)} sure.',
            style: hint,
          ),
          CategorySource.user => Text('You chose this.', style: hint),
          CategorySource.youtube => Text(
            key: CategoryWindow.youtubeSourceKey,
            topicLabels.isNotEmpty
                ? 'From the topics YouTube gives this channel: '
                      '${topicLabels.join(', ')}.'
                : signedIn
                ? 'YouTube gives this channel no topics to tell its category '
                      'by.'
                : _signInForTopics,
            style: hint,
          ),
        },
        if (category.source == CategorySource.youtube && jevAgreed != null) ...[
          const SizedBox(height: 8),
          Text(
            'Jev checked it: ${_percent(jevAgreed)} sure it fits.',
            style: hint,
          ),
        ],
        if (category.source != CategorySource.user)
          switch (category.userDecision) {
            UserDecision.none => const SizedBox.shrink(),
            UserDecision.accepted => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('You chose this.', style: hint),
            ),
            UserDecision.denied => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("You kept this; it won't be changed.", style: hint),
            ),
          },
        if (category.source == CategorySource.jev &&
            category.runnersUp.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text('Next most likely', style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: 4),
          for (final runner in category.runnersUp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${runner.path.label} · ${_percent(runner.score)}',
                style: hint,
              ),
            ),
        ],
      ],
    );
  }
}
