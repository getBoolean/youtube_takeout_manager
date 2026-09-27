import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/search_match_marker.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/comment_spans.dart';
import '../application/emoji_names.dart';
import '../domain/emoji_key.dart';
import '../domain/emoji_shortcode.dart';
import 'emoji_image.dart';
import 'emoji_url_menu.dart';

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
