import 'package:flutter/material.dart';

import '../domain/emoji_key.dart';
import '../domain/picker_emoji.dart';

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

  /// Key of the placeholder shown instead of a missing image.
  static const placeholderKey = ValueKey('emoji-image-placeholder');

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
      key: placeholderKey,
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
