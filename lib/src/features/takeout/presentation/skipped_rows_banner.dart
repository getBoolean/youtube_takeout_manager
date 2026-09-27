import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/notice_banner.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';

/// Says how many of a takeout's comment and live chat rows couldn't be read,
/// so they're missing from it. Shows nothing when none were skipped.
class SkippedRowsBanner extends StatelessWidget {
  final int comments;
  final int liveChats;

  const SkippedRowsBanner({
    super.key,
    required this.comments,
    required this.liveChats,
  });

  @override
  Widget build(BuildContext context) {
    if (comments == 0 && liveChats == 0) return const SizedBox.shrink();
    final skipped = [
      if (comments > 0) formatCount(comments, 'comment'),
      if (liveChats > 0) formatCount(liveChats, 'live chat'),
    ].join(' and ');
    final were = comments + liveChats == 1 ? 'was' : 'were';
    return NoticeBanner(
      title: "Some rows couldn't be read",
      children: [
        Text("$skipped $were skipped, so they aren't shown or deleted."),
      ],
    );
  }
}
