import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../application/category_editor.dart';
import '../application/channel_categories.dart';
import '../domain/channel_category.dart';
import 'category_colors.dart';
import 'category_sheet.dart';

/// A channel's category as a small pill tinted with its colour, its emoji
/// then its name, marked when an AI chose it; "Uncategorized" in a grey
/// outline when it has none, or none yet. Then each of its tags as a small
/// pill, wrapping. All one button, at least 48 points tall, apart from what
/// it sits in, opening the category's window. Without [showCategory], as
/// under its category, only the tags, and nothing without tags.
class ChannelCategoryChips extends ConsumerWidget {
  static const tapKey = ValueKey('channel-category-chips');

  final HistoryChannel channel;
  final bool showCategory;

  const ChannelCategoryChips({
    super.key,
    required this.channel,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(
      channelCategoriesProvider.select((m) => m.value?[channel.key]),
    );
    final tags = category?.tags ?? const <String>[];
    if (!showCategory && tags.isEmpty) return const SizedBox.shrink();
    final emojiOf = ref.watch(categoryEmojiOfProvider);
    final path = category?.path;
    final label = path?.label ?? 'Uncategorized';
    final source = switch (category) {
      null || ChannelCategory(path: null) => null,
      ChannelCategory(isAi: true) => 'chosen by AI',
      ChannelCategory(source: CategorySource.user) => 'chosen by you',
      _ => "from YouTube's topics",
    };

    return Semantics(
      button: true,
      label: [
        if (showCategory)
          source == null ? 'Uncategorized' : 'Category $label, $source',
        if (tags.isNotEmpty) 'Tags: ${tags.join(', ')}',
      ].join('. '),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: tapKey,
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            // Read now: the chip may be gone once the window closes.
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (showCategory)
                    _CategoryPill(
                      parent: path?.parent,
                      emoji: emojiOf(path),
                      label: label,
                      ai: category?.isAi ?? false,
                    ),
                  for (final tag in tags) _TagPill(tag),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The category, tinted with its colour, or outlined grey without one.
class _CategoryPill extends StatelessWidget {
  final String? parent;
  final String emoji;
  final String label;
  final bool ai;

  const _CategoryPill({
    required this.parent,
    required this.emoji,
    required this.label,
    required this.ai,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final none = parent == null;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: none ? Colors.transparent : categoryTint(parent, scheme),
        shape: StadiumBorder(
          side: none
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: theme.textTheme.labelMedium),
            const SizedBox(width: 4),
            if (ai) ...[
              AiMark(size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: none ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tag, as a small plain pill.
class _TagPill extends StatelessWidget {
  final String tag;

  const _TagPill(this.tag);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          tag,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
