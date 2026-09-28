import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:youtube_takeout_manager/src/common_widgets/actions_sheet.dart';
import 'package:youtube_takeout_manager/src/common_widgets/video_thumbnail.dart';
import '../domain/search_entry.dart';
import '../domain/watch_entry.dart';
import '../domain/watched_channels.dart';

/// What can be done with a watched video from its actions sheet.
enum WatchAction { open, showChannel, openChannel, copyLink }

/// Offers what can be done with [watch], under its thumbnail, title and
/// channel. Returns the pick, or null if the sheet was dismissed.
Future<WatchAction?> showWatchActionsSheet(
  BuildContext context,
  WatchEntry watch,
) {
  final channel = HistoryChannel.of(watch);
  final theme = Theme.of(context);
  return showActionsSheet(
    context,
    header: Row(
      children: [
        SizedBox(
          width: 64,
          height: 36,
          child: VideoThumbnail(
            url: switch (watch.videoId) {
              final id? => 'https://i.ytimg.com/vi/$id/mqdefault.jpg',
              null => null,
            },
            placeholderIcon: Icons.videocam_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                watch.title ?? watch.url,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (watch.channelTitle case final name?)
                Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    ),
    options: [
      SheetOption(
        WatchAction.open,
        Icons.open_in_new,
        watch.music ? 'Open on YouTube Music' : 'Open on YouTube',
      ),
      if (channel != null) ...[
        SheetOption(
          WatchAction.showChannel,
          Icons.filter_list,
          'Show all from ${channel.title}',
          'Only the videos watched from this channel',
        ),
        if (channel.channelUrl != null)
          SheetOption(
            WatchAction.openChannel,
            Icons.account_circle_outlined,
            'Open ${channel.title} on YouTube',
          ),
      ],
      const SheetOption(WatchAction.copyLink, Icons.link, 'Copy link'),
    ],
  );
}

/// What can be done with a search from its actions sheet.
enum SearchAction { search, copy }

/// Offers what can be done with [search], under what was searched for.
/// Returns the pick, or null if the sheet was dismissed.
Future<SearchAction?> showSearchActionsSheet(
  BuildContext context,
  SearchEntry search,
) => showActionsSheet(
  context,
  header: Text(
    search.query,
    style: Theme.of(context).textTheme.titleSmall,
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
  ),
  options: [
    SheetOption(
      SearchAction.search,
      Icons.open_in_new,
      search.music ? 'Search on YouTube Music' : 'Search on YouTube',
    ),
    const SheetOption(SearchAction.copy, Icons.copy, 'Copy search'),
  ],
);

/// Opens [url] in the browser or YouTube app.
Future<void> openExternally(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Copies [text], saying so as [what] was copied.
Future<void> copyToClipboard(
  BuildContext context,
  String text,
  String what,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text('$what copied')));
}
