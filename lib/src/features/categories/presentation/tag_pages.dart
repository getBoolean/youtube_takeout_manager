import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../application/channel_tags.dart';
import '../domain/channel_category.dart';
import '../domain/sub_category.dart';
import '../domain/tag_name.dart';
import 'category_colors.dart';

/// The tags of [tags] whose name or meaning holds [text], whatever its case
/// or accents; all of them for none.
List<KeptTag> tagsMatching(List<KeptTag> tags, String text) {
  final folded = foldForSearch(text.trim());
  if (folded.isEmpty) return tags;
  return [
    for (final kept in tags)
      if (foldForSearch(kept.tag.name).contains(folded) ||
          foldForSearch(kept.tag.meaning ?? '').contains(folded))
        kept,
  ];
}

/// The tags kept, to define or change: a search over their names and
/// meanings, pinned at the top, "Define a tag" first, then every tag, the
/// user's first, each with its meaning and how many channels have it, ✨
/// when AI named it. Built lazily however many there are. [onOpen] opens a
/// tag by its folded name, or a new one for none. [header] comes first.
class TagsPage extends HookConsumerWidget {
  static const searchKey = ValueKey('tags-search');
  static const defineKey = ValueKey('tags-define');

  static ValueKey<String> rowKey(String key) => ValueKey('tags-row-$key');

  final ValueChanged<String?> onOpen;
  final Widget? header;

  const TagsPage({super.key, required this.onOpen, this.header});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tiny = isTinyWidth(context);
    final indent = tiny ? 8.0 : 24.0;
    final controller = useTextEditingController();
    final text = useValueListenable(controller).text;
    final tags = ref.watch(tagRegistryProvider);
    final rows = useMemoized(() => tagsMatching(tags, text), [tags, text]);
    return SliverMainAxisGroup(
      slivers: [
        if (header case final header?) SliverToBoxAdapter(child: header),
        PinnedHeaderSliver(
          child: ColoredBox(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.fromLTRB(indent, 8, indent, 8),
              child: TextField(
                key: searchKey,
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: tiny ? null : const Icon(Icons.search),
                  hintText: 'Find a tag by name or meaning',
                ),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: rows.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return ListTile(
                key: defineKey,
                contentPadding: EdgeInsets.symmetric(horizontal: indent),
                leading: const Icon(Icons.add),
                title: const Text('Define a tag'),
                onTap: () => onOpen(null),
              );
            }
            final (:key, :tag, :channels) = rows[i - 1];
            final meaning = tag.meaning;
            return ListTile(
              key: rowKey(key),
              contentPadding: EdgeInsets.symmetric(horizontal: indent),
              leading: tag.origin == NameOrigin.ai
                  ? AiMark(size: 20, color: scheme.onSurfaceVariant)
                  : const Icon(Icons.sell_outlined),
              title: Text(tag.name),
              subtitle: Text(
                [
                  meaning ?? 'No meaning: AI leaves it where you put it',
                  formatCount(channels, 'channel'),
                ].join(' · '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onOpen(key),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// A tag's name and meaning, to define or change: the name only for a new
/// one ([name] is an existing tag's), starting from [initialName]; the
/// meaning, at most [maxTagMeaning] long, saying that AI gives a tag only
/// through it. [onSave] keeps them; [onDelete], when given, deletes the
/// tag once asked in place.
class TagForm extends HookWidget {
  static const nameKey = ValueKey('tag-name');
  static const meaningKey = ValueKey('tag-meaning');
  static const saveKey = ValueKey('tag-save');
  static const deleteKey = ValueKey('tag-delete');
  static const confirmDeleteKey = ValueKey('tag-delete-confirm');

  final String? name;
  final String initialName;
  final String? initialMeaning;
  final Future<void> Function(String name, String? meaning) onSave;
  final Future<void> Function()? onDelete;

  const TagForm({
    super.key,
    this.name,
    this.initialName = '',
    this.initialMeaning,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiny = isTinyWidth(context);
    final nameField = useTextEditingController(text: name ?? initialName);
    final meaningField = useTextEditingController(text: initialMeaning ?? '');
    final typed = useValueListenable(nameField).text;
    final asking = useState(false);
    final saving = useState(false);
    final canSave = tidyTagName(typed) != null && !saving.value;
    Future<void> save() async {
      saving.value = true;
      try {
        await onSave(nameField.text, meaningField.text);
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 8 : 24, 8, tiny ? 8 : 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name case final name?)
            Text(name, style: theme.textTheme.titleMedium)
          else
            TextField(
              key: nameKey,
              controller: nameField,
              maxLength: maxTagName,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            key: meaningKey,
            controller: meaningField,
            maxLength: maxTagMeaning,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Meaning',
              hintText: 'What a channel with this tag is about',
            ),
          ),
          Text(
            'AI gives this tag to the channels its meaning fits. Without a '
            'meaning, it stays only where you put it.',
            style: hint,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onDelete != null && !asking.value)
                TextButton.icon(
                  key: deleteKey,
                  onPressed: () => asking.value = true,
                  icon: tiny ? null : const Icon(Icons.delete_outline),
                  label: const Text('Delete', textAlign: TextAlign.center),
                ),
              FilledButton(
                key: saveKey,
                onPressed: canSave ? save : null,
                child: const Text('Save', textAlign: TextAlign.center),
              ),
            ],
          ),
          if (asking.value) ...[
            const SizedBox(height: 16),
            Text(
              'Delete ${name ?? 'this tag'} from every channel? It never '
              'comes back on its own.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => asking.value = false,
                  child: const Text('Cancel', textAlign: TextAlign.center),
                ),
                FilledButton(
                  key: confirmDeleteKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: () => onDelete!(),
                  child: const Text('Delete', textAlign: TextAlign.center),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
