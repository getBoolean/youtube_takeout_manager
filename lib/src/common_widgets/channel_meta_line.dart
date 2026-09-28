import 'package:flutter/material.dart';

import 'fade_in_picture.dart';

/// The line under a listed item: [prefix], the channel's picture and
/// [channelName], then [detail] (e.g. when). The channel's name ellipsizes
/// when narrow, but [detail] is never cut off: when both wouldn't fit on
/// one line, it goes on its own. Without a channel it's just the detail.
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

  static const _pictureSize = 14.0;
  static const _pictureGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final channelName = this.channelName;
    if (channelName == null) return Text(detail, style: style);

    return LayoutBuilder(
      builder: (context, constraints) {
        final oneLine = '$prefix$channelName · $detail';
        final painter = TextPainter(
          text: TextSpan(text: oneLine, style: style),
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
          maxLines: 1,
        )..layout();
        final width =
            painter.width +
            (thumbnailUrl == null ? 0 : _pictureSize + _pictureGap);
        painter.dispose();
        final fits = width <= constraints.maxWidth;

        final channel = Text.rich(
          TextSpan(
            children: [
              if (prefix.isNotEmpty) TextSpan(text: prefix),
              if (thumbnailUrl case final url?)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: _pictureGap),
                    child: ClipOval(
                      child: NetworkPicture(
                        url: url,
                        width: _pictureSize,
                        height: _pictureSize,
                        htmlElementOnWeb: true,
                        // Until it loads, and when it won't, so the name
                        // doesn't move.
                        placeholder: _PictureDot(),
                      ),
                    ),
                  ),
                ),
              TextSpan(text: fits ? '$channelName · $detail' : channelName),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
        if (fits) return channel;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            channel,
            Text(detail, style: style),
          ],
        );
      },
    );
  }
}

/// Where a channel's picture goes, while there's none to show.
class _PictureDot extends StatelessWidget {
  const _PictureDot();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: ChannelMetaLine._pictureSize,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
    ),
  );
}
