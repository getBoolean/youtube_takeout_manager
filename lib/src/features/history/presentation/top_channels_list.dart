import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/watched_channels.dart';

/// The channels videos were watched from, the most watched first.
class TopChannelsList extends StatelessWidget {
  final List<WatchedChannel> channels;

  /// Channel pictures by channel ID.
  final Map<String, String> pictures;

  /// Highlighted in the names; empty for none.
  final String query;
  final ValueChanged<HistoryChannel> onPick;

  /// Told the ID of each channel as its row is built.
  final ValueChanged<String>? onChannelShown;

  const TopChannelsList({
    super.key,
    required this.channels,
    required this.pictures,
    required this.query,
    required this.onPick,
    this.onChannelShown,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, i) {
        final watched = channels[i];
        final channel = watched.channel;
        if (channel.channelId case final id?) onChannelShown?.call(id);
        final videos = formatCount(
          watched.count,
          watched.byTitle ? 'matching video' : 'video',
        );
        return ListTile(
          leading: ChannelAvatar(
            name: channel.title,
            thumbnailUrl: pictures[channel.channelId],
            radius: 20,
          ),
          title: HighlightedText(
            channel.title,
            // Found by the titles of its videos, its name doesn't match.
            query: watched.byTitle ? '' : query,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$videos · last watched ${formatDate(watched.lastWatched)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onPick(channel),
        );
      },
    );
  }
}
