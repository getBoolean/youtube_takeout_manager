import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/image_url_menu.dart';

/// A video's thumbnail with rounded corners, filling the size its parent
/// gives it. Shows [placeholderIcon] when there's no [url] or the picture
/// won't load. Its URL can be copied on right-click when [copyable].
class VideoThumbnail extends StatelessWidget {
  final String? url;
  final IconData placeholderIcon;

  /// The width it's shown at, in logical pixels, when known: the picture is
  /// then decoded no bigger, which saves memory and drawing time in long
  /// lists.
  final double? width;

  /// Whether its URL can be copied on right-click.
  final bool copyable;

  const VideoThumbnail({
    super.key,
    required this.url,
    required this.placeholderIcon,
    this.width,
    this.copyable = true,
  });

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) return _Placeholder(placeholderIcon);
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: switch (width) {
          final w? => (w * MediaQuery.devicePixelRatioOf(context)).ceil(),
          null => null,
        },
        errorBuilder: (_, _, _) => _Placeholder(placeholderIcon),
      ),
    );
    if (!copyable) return image;
    // Right-click only: a long press on a row may start selection.
    return ImageUrlMenu(url: url, child: image);
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;

  const _Placeholder(this.icon);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Icon(icon, color: colors.onSurfaceVariant)),
    );
  }
}
