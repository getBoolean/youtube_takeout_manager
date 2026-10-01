import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../application/category_editor.dart';
import '../application/channel_categories.dart';
import 'category_sheet.dart';

/// A channel's category as a small tonal pill, marked when an AI chose it;
/// "Uncategorized" when nothing could tell, nothing while it's still to be
/// decided. Tapping it explains where it came from. It stays on one line;
/// the explanation has it in full.
class ChannelCategoryChip extends ConsumerWidget {
  /// Marks a category an AI chose.
  static const aiIcon = Icons.auto_awesome;

  final HistoryChannel channel;

  const ChannelCategoryChip({super.key, required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(
      channelCategoriesProvider.select((m) => m.value?[channel.key]),
    );
    if (category == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final path = category.path;
    final label = path?.label ?? 'Uncategorized';
    final ai = category.isAi;
    final foreground = path == null
        ? scheme.onSurfaceVariant
        : scheme.onSecondaryContainer;

    return Semantics(
      button: true,
      label: path == null
          ? 'Uncategorized'
          : ai
          ? 'Category $label, chosen by AI'
          : "Category $label, from YouTube's topics",
      excludeSemantics: true,
      child: Material(
        color: path == null ? Colors.transparent : scheme.secondaryContainer,
        shape: StadiumBorder(
          side: path == null
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            // Read now: the chip may be gone once the modal closes.
            final editor = ref.read(categoryEditorProvider.notifier);
            final result = await showCategorySheet(context, channel: channel);
            switch (result) {
              case AcceptedSuggestion(:final suggestion):
                await editor.accept(channel, suggestion);
              case KeptCategory():
                await editor.deny(channel);
              case null:
                break;
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ai) ...[
                  Icon(aiIcon, size: 16, color: foreground),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
