import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import '../application/history_grouping.dart';
import 'grouping_sheet.dart';

/// Over the watched videos: how they're grouped, the filters on, and
/// collapsing or expanding every group. The buttons wrap onto more rows
/// rather than squeezing their labels.
class HistoryToolbar extends StatelessWidget {
  static const groupByKey = ValueKey('history-group-by');
  static const filtersKey = ValueKey('history-filters');
  static const collapseAllKey = ValueKey('history-collapse-all');
  static const expandAllKey = ValueKey('history-expand-all');

  final HistoryGrouping grouping;

  /// How many filters are on.
  final int activeFilters;
  final VoidCallback onGroupBy;
  final VoidCallback onFilters;
  final VoidCallback onCollapseAll;
  final VoidCallback onExpandAll;

  const HistoryToolbar({
    super.key,
    required this.grouping,
    required this.activeFilters,
    required this.onGroupBy,
    required this.onFilters,
    required this.onCollapseAll,
    required this.onExpandAll,
  });

  @override
  Widget build(BuildContext context) {
    final tiny = isTinyWidth(context);
    final compact = isCompactWidth(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: 'Group by ${grouping.label.toLowerCase()}',
          child: FilledButton.tonalIcon(
            key: groupByKey,
            onPressed: onGroupBy,
            icon: tiny ? null : Icon(grouping.icon),
            label: Text(
              compact ? grouping.label : 'Group by: ${grouping.label}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        FilledButton.tonalIcon(
          key: filtersKey,
          onPressed: onFilters,
          icon: tiny
              ? null
              : Icon(activeFilters > 0 ? Icons.tune : Icons.tune_outlined),
          label: Text(
            activeFilters > 0 ? 'Filters · $activeFilters' : 'Filters',
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          key: collapseAllKey,
          tooltip: 'Collapse all',
          onPressed: onCollapseAll,
          icon: const Icon(Icons.unfold_less),
        ),
        IconButton(
          key: expandAllKey,
          tooltip: 'Expand all',
          onPressed: onExpandAll,
          icon: const Icon(Icons.unfold_more),
        ),
      ],
    );
  }
}
