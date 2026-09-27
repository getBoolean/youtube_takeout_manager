import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/scroll_target_highlight.dart';
import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/sticky_grouped_list.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_list/section_header.dart';
import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import 'package:youtube_takeout_manager/src/utils/date_formatter.dart';
import '../domain/history_days.dart';

/// History entries under a sticky header for each day, built lazily however
/// many there are. Entries are indices into the history's list of them.
class HistoryDayList extends StatelessWidget {
  final List<HistoryDay> days;
  final StickyGroupedListController controller;
  final ScrollController scrollController;

  /// What one entry is called in a day's count, e.g. "video".
  final String noun;
  final String? plural;

  /// The entry to highlight, once, having jumped to it.
  final int? highlighted;
  final VoidCallback onHighlightDone;

  final Widget Function(BuildContext context, int index) entryBuilder;

  const HistoryDayList({
    super.key,
    required this.days,
    required this.controller,
    required this.scrollController,
    required this.noun,
    this.plural,
    required this.highlighted,
    required this.onHighlightDone,
    required this.entryBuilder,
  });

  /// Days have no header state; the list needs one per header regardless.
  static const _noState = Object();

  @override
  Widget build(BuildContext context) {
    return StickyGroupedListView<HistoryDay, int, Object>(
      groups: days,
      groupKey: (day) => day.dayKey,
      itemsOf: (day) => day.indices,
      itemKey: (index) => index,
      controller: controller,
      scrollController: scrollController,
      // Keeps its place while another tab is open.
      keepAlive: true,
      createHeaderState: (_, _, _) => _noState,
      updateHeaderState: (_, _, _) {},
      disposeHeaderState: (_) {},
      headerBuilder: (context, day, _, _) => SectionHeader(
        label:
            '${formatDay(day.day)} · '
            '${formatCount(day.indices.length, noun, plural: plural)}',
      ),
      itemBuilder: (context, day, index, _) {
        final entry = entryBuilder(context, index);
        if (index != highlighted) return entry;
        return ScrollTargetHighlight(
          active: true,
          onComplete: onHighlightDone,
          child: entry,
        );
      },
      trailing: const SliverToBoxAdapter(child: SizedBox(height: 24)),
    );
  }
}
