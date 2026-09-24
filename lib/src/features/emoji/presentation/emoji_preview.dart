import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../service/emoji_providers.dart';

/// A custom emoji image that shows a larger preview with its `:name:` on
/// hover (desktop) or tap/click, like Discord.
class EmojiPreview extends ConsumerStatefulWidget {
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
  ConsumerState<EmojiPreview> createState() => _EmojiPreviewState();
}

class _EmojiPreviewState extends ConsumerState<EmojiPreview> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = widget.url;
    final key = emojiKey(url);
    final lookedUp = widget.name == null
        ? ref.watch(emojiNamesByKeyProvider.select((names) => names[key]))
        : null;
    final displayName = widget.name ?? lookedUp ?? fallbackEmojiName(key);
    final isResolved =
        widget.resolved ?? (widget.name != null || lookedUp != null);

    return Tooltip(
      key: _tooltipKey,
      // Taps are handled below so the emoji wins over an enclosing tappable
      // (e.g. a comment ListTile) and a click keeps the hover preview open.
      triggerMode: TooltipTriggerMode.manual,
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tooltipKey.currentState?.ensureTooltipVisible(),
        child: EmojiImage(url: url, size: widget.size),
      ),
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
