import 'package:flutter/material.dart';

import 'fade_in_picture.dart';

/// A channel's picture, or its initial when there's none, while it loads,
/// or when it won't load.
class ChannelAvatar extends StatelessWidget {
  final String name;
  final String? thumbnailUrl;
  final double radius;

  /// Shown instead of the picture or initial, e.g. for items whose channel
  /// isn't known.
  final IconData? icon;

  const ChannelAvatar({
    super.key,
    required this.name,
    this.thumbnailUrl,
    required this.radius,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = this.icon;
    final initial = Text(
      name.isEmpty ? '?' : name[0].toUpperCase(),
      style: TextStyle(
        fontSize: radius * 0.9,
        color: scheme.onPrimaryContainer,
      ),
    );
    final url = thumbnailUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: icon != null
          ? Icon(icon, size: radius * 1.1, color: scheme.onPrimaryContainer)
          : url == null
          ? initial
          : ClipOval(
              child: NetworkPicture(
                url: url,
                width: radius * 2,
                height: radius * 2,
                htmlElementOnWeb: true,
                // Until it loads, and when it won't.
                placeholder: Center(child: initial),
              ),
            ),
    );
  }
}
