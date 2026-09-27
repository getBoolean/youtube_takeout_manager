import 'package:intl/intl.dart';

import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../domain/takeout_channel.dart';

/// A channel's comment and live chat counts, e.g. "1,234 comments · 5 live
/// chats".
String describeChannelCounts(TakeoutChannel channel) =>
    _describeCounts(channel.commentCount, channel.liveChatCount);

/// A saved takeout's channel count, item counts and export date, as far as
/// they're known, e.g. "2 channels · 1,234 comments · 56 live chats ·
/// exported Apr 12, 2026".
String describeTakeout(TakeoutSummary summary) {
  final channels = summary.channels.length;
  final comments = summary.channels.fold(0, (n, c) => n + c.commentCount);
  final liveChats = summary.channels.fold(0, (n, c) => n + c.liveChatCount);
  return [
    if (channels > 1) '$channels channels',
    if (summary.countsKnown) _describeCounts(comments, liveChats),
    if (summary.latestExportAt case final exported?)
      'exported ${DateFormat.yMMMd().format(exported.toLocal())}',
  ].join(' · ');
}

String _describeCounts(int comments, int liveChats) => [
  formatCount(comments, 'comment'),
  formatCount(liveChats, 'live chat'),
].join(' · ');
