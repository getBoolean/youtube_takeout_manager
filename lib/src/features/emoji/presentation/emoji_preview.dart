import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/image_url_menu.dart';
import 'package:youtube_takeout_manager/src/common_widgets/search_match_marker.dart';
import 'package:youtube_takeout_manager/src/utils/comment_text_parser.dart';
import '../application/emoji_providers.dart';
import '../domain/picker_emoji.dart';

/// A custom emoji image that shows a larger preview with its `:name:` on
/// hover (desktop) or tap/click, like Discord.
class EmojiPreview extends ConsumerStatefulWidget {
  final String url;
  final double size;

  /// Overrides the name looked up from [emojiNamesByKeyProvider].
  final String? name;
  final bool? resolved;

  /// Marks the emoji when this search query looks for it by name (see
  /// [emojiMatchesQuery]).
  final String? highlightQuery;

  /// The emojis directly before and after this one, so a run of matched
  /// emojis gets one continuous marker.
  final AdjacentEmojis adjacent;

  /// Whether a tap/click opens the preview. When false, taps pass through
  /// (e.g. to place the caret in a text field) and only hover previews.
  final bool tapToPreview;

  const EmojiPreview({
    super.key,
    required this.url,
    required this.size,
    this.name,
    this.resolved,
    this.highlightQuery,
    this.adjacent = (previousUrl: null, nextUrl: null),
    this.tapToPreview = true,
  });

  /// Key of the marker drawn around an emoji matched by [highlightQuery].
  static const searchMatchKey = ValueKey('emoji-search-match');

  /// For `buildCommentSpans(emojiBuilder: ...)`, marking emojis that [query]
  /// searches for.
  static EmojiSpanBuilder highlighting(String? query) =>
      (url, size, adjacent) => EmojiPreview(
        url: url,
        size: size,
        highlightQuery: query,
        adjacent: adjacent,
      );

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

    final query = widget.highlightQuery;
    bool adjacentMatches(String? url) {
      if (url == null) return false;
      final key = emojiKey(url);
      final name =
          ref.watch(emojiNamesByKeyProvider.select((names) => names[key])) ??
          fallbackEmojiName(key);
      return emojiMatchesQuery(name, query!);
    }

    Widget emoji = EmojiImage(url: url, size: widget.size);
    if (query != null && emojiMatchesQuery(displayName, query)) {
      emoji = SearchMatchMarker(
        key: EmojiPreview.searchMatchKey,
        joinsPrevious: adjacentMatches(widget.adjacent.previousUrl),
        joinsNext: adjacentMatches(widget.adjacent.nextUrl),
        child: emoji,
      );
    }

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
      child: widget.tapToPreview
          ? EmojiUrlMenu(
              url: url,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _tooltipKey.currentState?.ensureTooltipVisible(),
                child: emoji,
              ),
            )
          : emoji,
    );
  }
}

/// Offers "Copy image URL" for a channel emoji's Takeout URL (see
/// [ImageUrlMenu]).
class EmojiUrlMenu extends StatelessWidget {
  final String url;
  final bool longPress;
  final Widget child;

  const EmojiUrlMenu({
    super.key,
    required this.url,
    this.longPress = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ImageUrlMenu(
    url: url,
    longPress: longPress,
    // Takeout writes "Failed to get emoji URL" for emojis it couldn't export.
    unavailableLabel: 'No image URL in Takeout',
    child: child,
  );
}

/// A picker emoji: a channel's image or a standard emoji's glyph.
class PickerEmojiImage extends StatelessWidget {
  final PickerEmoji emoji;
  final double size;

  const PickerEmojiImage({super.key, required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) {
    return switch (emoji) {
      CustomPickerEmoji(:final emoji) => EmojiImage(url: emoji.url, size: size),
      UnicodePickerEmoji(:final emoji) => EmojiGlyph(
        emoji: emoji.emoji,
        size: size,
      ),
    };
  }
}

/// A standard emoji drawn with the platform emoji font in a [size] square,
/// so it lines up with [EmojiImage]s.
class EmojiGlyph extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiGlyph({super.key, required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Text(
          emoji,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontSize: size * 0.8, height: 1),
        ),
      ),
    );
  }
}

/// A custom emoji image with a visible placeholder when it can't be loaded
/// (e.g. the channel deleted the emoji and its URL now returns 404).
class EmojiImage extends StatelessWidget {
  final String url;
  final double size;

  /// Adds a caption under the placeholder saying why there's no image.
  final bool explainMissing;

  const EmojiImage({
    super.key,
    required this.url,
    required this.size,
    this.explainMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEmojiImageUrl(url)) {
      return _placeholder(context, 'Not included in Takeout');
    }
    return Image.network(
      url,
      width: size,
      height: size,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (context, _, _) =>
          _placeholder(context, 'Image no longer available'),
    );
  }

  Widget _placeholder(BuildContext context, String reason) {
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
          reason,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
