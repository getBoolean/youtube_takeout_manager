import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/watched_channels.dart';

/// The channels videos were watched from, the most watched first.
class TopChannelsList extends StatelessWidget {
  final List<WatchedChannel> channels;

  /// Highlighted in the names; empty for none.
  final String query;
  final ValueChanged<HistoryChannel> onPick;

  const TopChannelsList({
    super.key,
    required this.channels,
    required this.query,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, i) {
        final watched = channels[i];
        final channel = watched.channel;
        return ListTile(
          leading: ChannelAvatar(name: channel.title, radius: 20),
          title: HighlightedText(
            channel.title,
            query: query,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${formatCount(watched.count, 'video')} · last '
            '${formatDay(watched.lastWatched)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onPick(channel),
        );
      },
    );
  }
}
