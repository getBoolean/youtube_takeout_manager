import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import '../../application/deletion_queue_counts.dart';
import '../../application/deletion_queue_filter.dart';

extension DeletionQueueFilterLabel on DeletionQueueFilter {
  String get label => switch (this) {
    DeletionQueueFilter.all => 'All',
    DeletionQueueFilter.waiting => 'Waiting',
    DeletionQueueFilter.failed => 'Failed',
    DeletionQueueFilter.done => 'Done',
  };
}

/// A chip per filter, with how many items it shows, [selected] picked.
class DeletionQueueFilterChips extends StatelessWidget {
  final DeletionQueueCounts counts;
  final DeletionQueueFilter selected;
  final ValueChanged<DeletionQueueFilter> onSelected;

  const DeletionQueueFilterChips({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final filter in DeletionQueueFilter.values)
            ChoiceChip(
              // The name gives way before the count when narrow.
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${filter.label} ',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedCountText(filter.countIn(counts)),
                ],
              ),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
            ),
        ],
      ),
    );
  }
}
