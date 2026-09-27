import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/image_url_menu.dart';

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
