import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/image_url_menu.dart';

/// A video's thumbnail with rounded corners, filling the size its parent
/// gives it. Shows [placeholderIcon] when there's no [url] or the picture
/// won't load. Its URL can be copied on right-click.
class VideoThumbnail extends StatelessWidget {
  final String? url;
  final IconData placeholderIcon;

  const VideoThumbnail({
    super.key,
    required this.url,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) return _Placeholder(placeholderIcon);
    // Right-click only: a long press on a row may start selection.
    return ImageUrlMenu(
      url: url,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _Placeholder(placeholderIcon),
        ),
      ),
    );
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
