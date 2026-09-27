import 'package:flutter/material.dart';

/// One line under a listed item: [prefix], the channel's picture and
/// [channelName], then [detail] (e.g. when). With the picture inline it
/// ellipsizes instead of overflowing when narrow. Without a channel it's
/// just the detail.
class ChannelMetaLine extends StatelessWidget {
  final String prefix;
  final String? channelName;
  final String? thumbnailUrl;
  final String detail;

  const ChannelMetaLine({
    super.key,
    this.prefix = '',
    this.channelName,
    this.thumbnailUrl,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelName = this.channelName;
    return Text.rich(
      TextSpan(
        children: [
          if (channelName != null) ...[
            if (prefix.isNotEmpty) TextSpan(text: prefix),
            if (thumbnailUrl case final url?)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipOval(
                    child: Image.network(
                      url,
                      width: 14,
                      height: 14,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      // A picture that won't load is left out.
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            TextSpan(text: '$channelName · $detail'),
          ] else
            TextSpan(text: detail),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
