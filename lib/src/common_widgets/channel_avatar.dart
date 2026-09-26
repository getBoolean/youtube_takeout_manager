import 'package:flutter/material.dart';

/// A channel's picture, or its initial when there's none or it won't load.
class ChannelAvatar extends StatelessWidget {
  final String name;
  final String? thumbnailUrl;
  final double radius;

  const ChannelAvatar({
    super.key,
    required this.name,
    this.thumbnailUrl,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
      child: url == null
          ? initial
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, _, _) => Center(child: initial),
              ),
            ),
    );
  }
}
