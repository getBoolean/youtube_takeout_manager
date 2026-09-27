import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/highlighted_text.dart';
import 'package:youtube_takeout_manager/src/common_widgets/label_badge.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/search_entry.dart';
import 'removed_badge.dart';

/// One search: what was searched for, and when in the day.
class SearchEntryTile extends StatelessWidget {
  final SearchEntry search;

  /// Highlighted in the query; empty for none.
  final String query;
  final VoidCallback onTap;

  const SearchEntryTile({
    super.key,
    required this.search,
    this.query = '',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final removedAt = search.removedAt;
    return ListTile(
      onTap: onTap,
      leading: Icon(search.music ? Icons.music_note_outlined : Icons.search),
      title: HighlightedText(
        search.query,
        query: query,
        style: theme.textTheme.bodyLarge,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(formatTime(search.time)),
          if (search.music) const LabelBadge('Music'),
          if (removedAt != null) RemovedBadge(removedAt: removedAt),
        ],
      ),
    );
  }
}
