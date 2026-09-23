import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/emoji_providers.dart';
import '../utils/comment_text_parser.dart';

/// A custom emoji image that shows a larger preview with its `:name:` on
/// hover (desktop) or tap (touch), like Discord.
class EmojiPreview extends ConsumerWidget {
  final String url;
  final double size;

  /// Overrides the name looked up from [emojiNamesByKeyProvider].
  final String? name;
  final bool? resolved;

  const EmojiPreview({
    super.key,
    required this.url,
    required this.size,
    this.name,
    this.resolved,
  });

  /// For `buildCommentSpans(emojiBuilder: ...)`.
  static Widget builder(String url, double size) =>
      EmojiPreview(url: url, size: size);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final key = emojiKey(url);
    final lookedUp = name == null
        ? ref.watch(emojiNamesByKeyProvider.select((names) => names[key]))
        : null;
    final displayName = name ?? lookedUp ?? fallbackEmojiName(key);
    final isResolved = resolved ?? (name != null || lookedUp != null);

    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      richMessage: WidgetSpan(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmojiImage(url: url, size: 56, explainMissing: true),
            const SizedBox(height: 6),
            Text(
              ':$displayName:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontStyle: isResolved ? null : FontStyle.italic,
              ),
            ),
            if (!isResolved)
              Text(
                'Generated name',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      child: EmojiImage(url: url, size: size),
    );
  }
}

/// A custom emoji image with a visible placeholder when it can't be loaded
/// (e.g. the channel deleted the emoji and its URL now returns 404).
class EmojiImage extends StatelessWidget {
  final String url;
  final double size;

  /// Adds an "Image unavailable" caption under the placeholder.
  final bool explainMissing;

  const EmojiImage({
    super.key,
    required this.url,
    required this.size,
    this.explainMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: size,
      height: size,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, _, _) {
        final theme = Theme.of(context);
        final placeholder = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size / 4),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            size: size * 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
        if (!explainMissing) return placeholder;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            placeholder,
            const SizedBox(height: 4),
            Text(
              'Image no longer available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
