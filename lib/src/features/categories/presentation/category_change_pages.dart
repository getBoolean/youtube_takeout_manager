import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/emoji/data/unicode_emoji_catalog.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/picker_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_picker_panel.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../application/category_editor.dart';
import '../application/channel_categories.dart';
import '../domain/category_emoji.dart';
import '../domain/category_path.dart';
import '../domain/category_prompts.dart';
import '../domain/sub_category.dart';
import '../domain/youtube_taxonomy.dart';
import 'category_colors.dart';
import 'category_window.dart';

/// A row of the Change category page.
sealed class ChangeRow {
  const ChangeRow();
}

/// A category, opening to its sub-categories when [open].
final class ChangeCategoryRow extends ChangeRow {
  final String parent;
  final bool open;

  const ChangeCategoryRow(this.parent, {this.open = false});

  @override
  bool operator ==(Object other) =>
      other is ChangeCategoryRow &&
      other.parent == parent &&
      other.open == open;

  @override
  int get hashCode => Object.hash(parent, open);
}

/// All of a category, whatever the sub-category.
final class ChangeAllOfRow extends ChangeRow {
  final String parent;

  const ChangeAllOfRow(this.parent);

  @override
  bool operator ==(Object other) =>
      other is ChangeAllOfRow && other.parent == parent;

  @override
  int get hashCode => parent.hashCode;
}

/// A sub-category.
final class ChangeSubRow extends ChangeRow {
  final String parent;
  final String child;

  const ChangeSubRow(this.parent, this.child);

  @override
  bool operator ==(Object other) =>
      other is ChangeSubRow && other.parent == parent && other.child == child;

  @override
  int get hashCode => Object.hash(parent, child);
}

/// Typing in a new sub-category of [parent].
final class ChangeNewSubRow extends ChangeRow {
  final String parent;

  const ChangeNewSubRow(this.parent);

  @override
  bool operator ==(Object other) =>
      other is ChangeNewSubRow && other.parent == parent;

  @override
  int get hashCode => parent.hashCode;
}

/// The rows of [taxonomy] to pick from: each category, and, for those
/// [open], all of it, its sub-categories and a new one. Searching for
/// [query] opens the categories it matches, to all their sub-categories,
/// and the others with sub-categories it matches, to those.
List<ChangeRow> changeRows(
  Taxonomy taxonomy, {
  Set<String> open = const {},
  String query = '',
}) {
  final folded = foldForSearch(query.trim());
  final rows = <ChangeRow>[];
  for (final parent in taxonomy.parents) {
    final children = taxonomy.childrenOf(parent);
    if (folded.isEmpty) {
      final opened = open.contains(parent);
      rows.add(ChangeCategoryRow(parent, open: opened));
      if (opened) {
        rows.addAll([
          ChangeAllOfRow(parent),
          for (final child in children) ChangeSubRow(parent, child),
          ChangeNewSubRow(parent),
        ]);
      }
      continue;
    }
    final whole = foldForSearch(parent).contains(folded);
    final matching = whole
        ? children
        : [
            for (final child in children)
              if (foldForSearch(child).contains(folded)) child,
          ];
    if (!whole && matching.isEmpty) continue;
    rows.addAll([
      ChangeCategoryRow(parent, open: true),
      if (whole) ChangeAllOfRow(parent),
      for (final child in matching) ChangeSubRow(parent, child),
      ChangeNewSubRow(parent),
    ]);
  }
  return rows;
}

/// A sub-category being typed in: under which category, its name, and the
/// emoji picked for it, shared by the pages that make it.
class NewSubCategoryDraft extends ChangeNotifier {
  var parent = '';
  var name = '';
  String? emoji;

  /// Raised each time a new one is started, so the name field starts empty.
  var started = 0;

  void start(String parent) {
    this.parent = parent;
    name = '';
    emoji = null;
    started++;
    notifyListeners();
  }

  void setName(String name) {
    this.name = name;
    notifyListeners();
  }

  void pick(String emoji) {
    this.emoji = emoji;
    notifyListeners();
  }
}

/// The pages for changing [channel]'s category: the categories to pick
/// from, typing in a new sub-category, and picking its emoji.
List<SliverWoltModalSheetPage> categoryChangePages(
  HistoryChannel channel,
  NewSubCategoryDraft draft,
) => [
  windowSliverPage(
    id: CategoryWindow.changeId,
    title: (context) => windowTitle(context, 'Change category'),
    backTo: CategoryWindow.mainId,
    slivers: [ChangePage(channel: channel, draft: draft)],
  ),
  windowPage(
    id: CategoryWindow.newSubId,
    title: (context) => windowTitle(context, 'New sub-category'),
    backTo: CategoryWindow.changeId,
    stickyActionBar: _AddBar(channel: channel, draft: draft),
    child: NewSubCategoryPage(draft: draft),
  ),
  windowPage(
    id: CategoryWindow.emojiId,
    title: (context) => windowTitle(context, 'Pick an emoji'),
    backTo: CategoryWindow.newSubId,
    child: Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        child: Center(
          child: EmojiPickerPanel(
            key: NewSubCategoryPage.pickerKey,
            groups: const [],
            standardEmojis: unicodeEmojiCatalog.all,
            onSelected: (emoji) {
              if (emoji is UnicodePickerEmoji) draft.pick(emoji.insertText);
              WoltModalSheet.of(
                context,
              ).showPageWithId(CategoryWindow.newSubId);
            },
          ),
        ),
      ),
    ),
  ),
];

/// The categories to pick [channel]'s from, under a search field pinned at
/// the top, each opening to its sub-categories, all of it, and a new one.
/// Built lazily however many there are.
class ChangePage extends HookConsumerWidget {
  static const searchKey = ValueKey('change-search');

  static ValueKey<String> categoryKey(String parent) =>
      ValueKey('change-category-$parent');
  static ValueKey<String> allOfKey(String parent) =>
      ValueKey('change-all-of-$parent');
  static ValueKey<String> subKey(String parent, String child) =>
      ValueKey('change-sub-$parent-$child');
  static ValueKey<String> newSubKey(String parent) =>
      ValueKey('change-new-sub-$parent');

  final HistoryChannel channel;
  final NewSubCategoryDraft draft;

  const ChangePage({super.key, required this.channel, required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final open = useState(const <String>{});
    final query = useState('');
    final taxonomy = ref.watch(categoryTaxonomyProvider);
    final custom = ref.watch(customCategoriesProvider).value ?? const {};
    final current = ref.watch(
      channelCategoriesProvider.select((m) => m.value?[channel.key]?.path),
    );
    final emojiOf = ref.watch(categoryEmojiOfProvider);
    final rows = useMemoized(
      () => changeRows(taxonomy, open: open.value, query: query.value),
      [taxonomy, open.value, query.value],
    );
    final indent = tiny ? 8.0 : 24.0;

    bool aiMade(String parent, String child) =>
        custom[parent]?.any(
          (sub) => sub.name == child && sub.origin == NameOrigin.ai,
        ) ??
        false;

    Future<void> pick(BuildContext context, CategoryPath path) async {
      final modal = WoltModalSheet.of(context);
      await ref.read(categoryEditorProvider.notifier).choose(channel, path);
      modal.showPageWithId(CategoryWindow.mainId);
    }

    Widget? ticked(CategoryPath path) =>
        current == path ? Icon(Icons.check, color: scheme.primary) : null;

    return SliverMainAxisGroup(
      slivers: [
        PinnedHeaderSliver(
          child: ColoredBox(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.fromLTRB(indent, 8, indent, 8),
              child: TextField(
                key: searchKey,
                onChanged: (text) => query.value = text,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: tiny ? null : const Icon(Icons.search),
                  hintText: 'Search categories',
                ),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) => switch (rows[i]) {
            ChangeCategoryRow(:final parent, open: final opened) => ListTile(
              key: categoryKey(parent),
              contentPadding: EdgeInsets.symmetric(horizontal: indent),
              leading: Text(
                categoryEmoji[parent] ?? uncategorizedEmoji,
                style: theme.textTheme.titleLarge,
              ),
              title: Text(parent),
              trailing: Icon(opened ? Icons.expand_less : Icons.expand_more),
              onTap: query.value.trim().isNotEmpty
                  ? null
                  : () => open.value = opened
                        ? ({...open.value}..remove(parent))
                        : {...open.value, parent},
            ),
            ChangeAllOfRow(:final parent) => ListTile(
              key: allOfKey(parent),
              contentPadding: EdgeInsetsDirectional.only(
                start: indent * 2,
                end: indent,
              ),
              title: Text('All of $parent'),
              trailing: ticked(CategoryPath(parent)),
              onTap: () => pick(context, CategoryPath(parent)),
            ),
            ChangeSubRow(:final parent, :final child) => ListTile(
              key: subKey(parent, child),
              contentPadding: EdgeInsetsDirectional.only(
                start: indent * 2,
                end: indent,
              ),
              leading: Text(
                emojiOf(CategoryPath(parent, child)),
                style: theme.textTheme.titleMedium,
              ),
              title: Row(
                children: [
                  Flexible(child: Text(child)),
                  if (aiMade(parent, child)) ...[
                    const SizedBox(width: 6),
                    AiMark(size: 16, color: scheme.onSurfaceVariant),
                  ],
                ],
              ),
              trailing: ticked(CategoryPath(parent, child)),
              onTap: () => pick(context, CategoryPath(parent, child)),
            ),
            ChangeNewSubRow(:final parent) => ListTile(
              key: newSubKey(parent),
              contentPadding: EdgeInsetsDirectional.only(
                start: indent * 2,
                end: indent,
              ),
              leading: const Icon(Icons.add),
              title: const Text('New sub-category…'),
              onTap: () {
                draft.start(parent);
                WoltModalSheet.of(
                  context,
                ).showPageWithId(CategoryWindow.newSubId);
              },
            ),
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// A new sub-category's name and emoji, as they're typed and picked.
class NewSubCategoryPage extends HookWidget {
  static const nameKey = ValueKey('new-sub-name');
  static const emojiKey = ValueKey('new-sub-emoji');
  static const addKey = ValueKey('new-sub-add');
  static const pickerKey = ValueKey('new-sub-picker');

  final NewSubCategoryDraft draft;

  const NewSubCategoryPage({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
    useListenable(draft);
    final controller = useTextEditingController(text: draft.name);
    // A new one starts empty.
    useEffect(() {
      if (controller.text != draft.name) controller.text = draft.name;
      return null;
    }, [draft.started]);
    final theme = Theme.of(context);
    final tiny = isTinyWidth(context);
    final parent = draft.parent;
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'A sub-category of $parent',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: nameKey,
            controller: controller,
            autofocus: true,
            maxLength: maxChildName,
            onChanged: draft.setName,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Emoji', style: theme.textTheme.titleSmall),
              OutlinedButton(
                key: emojiKey,
                onPressed: () => WoltModalSheet.of(
                  context,
                ).showPageWithId(CategoryWindow.emojiId),
                child: Text(
                  draft.emoji ?? categoryEmoji[parent] ?? uncategorizedEmoji,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Adds the sub-category typed in and makes it [channel]'s, back in the
/// window; only once it has a name.
class _AddBar extends HookConsumerWidget {
  final HistoryChannel channel;
  final NewSubCategoryDraft draft;

  const _AddBar({required this.channel, required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(draft);
    final tiny = isTinyWidth(context);
    final named = normalizeChildName(draft.name) != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 16),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FilledButton(
          key: NewSubCategoryPage.addKey,
          onPressed: !named
              ? null
              : () async {
                  final modal = WoltModalSheet.of(context);
                  final editor = ref.read(categoryEditorProvider.notifier);
                  final path = await editor.addSubCategory(
                    draft.parent,
                    draft.name,
                    emoji: draft.emoji,
                  );
                  await editor.choose(channel, path);
                  modal.showPageWithId(CategoryWindow.mainId);
                },
          child: const Text('Add', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
