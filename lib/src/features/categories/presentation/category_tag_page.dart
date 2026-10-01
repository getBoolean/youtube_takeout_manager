import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/utils/search_folding.dart';
import '../application/category_editor.dart';
import '../application/channel_categories.dart';
import '../application/channel_tags.dart';
import '../domain/channel_category.dart';
import '../domain/name_key.dart';
import '../domain/sub_category.dart';
import '../domain/tag_name.dart';
import 'category_colors.dart';
import 'category_window.dart';

/// A tag offered to add: one in use, or [isNew], the text typed.
typedef TagRow = ({String name, bool isNew, bool aiMade, int channels});

/// The tags to offer a channel that [has] some: [text] as a new tag first,
/// unless a tag there is folds the same; then the tags in [usage] it hasn't,
/// the most used first, matching [text] whatever its case, accents,
/// hyphens or spaces.
List<TagRow> tagRows(
  List<TagUse> usage, {
  required List<String> has,
  String text = '',
}) {
  final tidy = tidyTagName(text);
  final folded = foldForSearch(text.trim());
  final key = tidy == null ? '' : nameKey(tidy);
  final had = {for (final tag in has) nameKey(tag)};
  final known =
      had.contains(key) || usage.any((use) => nameKey(use.name) == key);
  return [
    if (tidy != null && !known)
      (name: tidy, isNew: true, aiMade: false, channels: 0),
    for (final use in usage)
      if (!had.contains(nameKey(use.name)) &&
          (folded.isEmpty ||
              foldForSearch(use.name).contains(folded) ||
              nameKey(use.name).contains(key)))
        (
          name: use.name,
          isNew: false,
          aiMade: use.origin == NameOrigin.ai,
          channels: use.channels,
        ),
  ];
}

/// Adding a tag to [channel]: a field pinned at the top, and the tags in use
/// it hasn't, or the text typed as a new one. Built lazily however many
/// there are; picking one adds it and goes back to the window.
class AddTagPage extends HookConsumerWidget {
  static const fieldKey = ValueKey('add-tag-field');
  static const newKey = ValueKey('add-tag-new');

  static ValueKey<String> rowKey(String tag) => ValueKey('add-tag-$tag');

  final HistoryChannel channel;

  const AddTagPage({super.key, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    final indent = tiny ? 8.0 : 24.0;
    final controller = useTextEditingController();
    final text = useValueListenable(controller).text;
    final has = ref.watch(
      channelCategoriesProvider.select(
        (m) => m.value?[channel.key]?.tags ?? const <String>[],
      ),
    );
    final usage = ref.watch(tagUsageProvider);
    final rows = useMemoized(() => tagRows(usage, has: has, text: text), [
      usage,
      has,
      text,
    ]);

    Future<void> add(BuildContext context, String tag) async {
      final modal = WoltModalSheet.of(context);
      await ref.read(categoryEditorProvider.notifier).setTags(channel, [
        ...has,
        tag,
      ]);
      controller.clear();
      modal.showPageWithId(CategoryWindow.mainId);
    }

    return SliverMainAxisGroup(
      slivers: [
        PinnedHeaderSliver(
          child: ColoredBox(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.fromLTRB(indent, 8, indent, 8),
              child: TextField(
                key: fieldKey,
                controller: controller,
                maxLength: maxTagName,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                  prefixIcon: tiny ? null : const Icon(Icons.search),
                  hintText: 'Find or type a tag',
                ),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final (:name, :isNew, :aiMade, :channels) = rows[i];
            return ListTile(
              key: isNew ? newKey : rowKey(name),
              contentPadding: EdgeInsets.symmetric(horizontal: indent),
              leading: isNew
                  ? const Icon(Icons.add)
                  : aiMade
                  ? AiMark(size: 20, color: scheme.onSurfaceVariant)
                  : const Icon(Icons.sell_outlined),
              title: Text(isNew ? 'Add "$name"' : name),
              subtitle: isNew ? null : Text(formatCount(channels, 'channel')),
              onTap: () => add(context, name),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
