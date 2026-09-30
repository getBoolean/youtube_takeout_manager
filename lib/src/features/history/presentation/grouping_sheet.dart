import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import '../application/history_grouping.dart';

/// What each way of grouping the watched videos is called, looks like, and
/// is for.
extension HistoryGroupingLabels on HistoryGrouping {
  String get label => switch (this) {
    HistoryGrouping.day => 'Day',
    HistoryGrouping.month => 'Month',
    HistoryGrouping.channel => 'Channel',
    HistoryGrouping.category => 'Category',
  };

  IconData get icon => switch (this) {
    HistoryGrouping.day => Icons.today_outlined,
    HistoryGrouping.month => Icons.calendar_month_outlined,
    HistoryGrouping.channel => Icons.video_library_outlined,
    HistoryGrouping.category => Icons.category_outlined,
  };

  String get description => switch (this) {
    HistoryGrouping.day => 'What you watched, a day at a time',
    HistoryGrouping.month => 'A month at a time, to see how much you watched',
    HistoryGrouping.channel =>
      'Every channel you watched or subscribe to, with what you watched '
          'from each',
    HistoryGrouping.category => 'By the kind of videos each channel makes',
  };
}

/// Asks how to group the watched videos, from the ways [available], with
/// [current] picked. Null when closed without picking.
Future<HistoryGrouping?> showGroupingSheet(
  BuildContext context, {
  required HistoryGrouping current,
  required List<HistoryGrouping> available,
}) => WoltModalSheet.show<HistoryGrouping>(
  context: context,
  pageListBuilder: (_) => [
    WoltModalSheetPage(
      topBarTitle: Semantics(
        header: true,
        child: Text(
          'Group by',
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: const Padding(
        padding: EdgeInsetsDirectional.only(end: 8),
        child: CloseButton(),
      ),
      child: GroupingSheet(current: current, available: available),
    ),
  ],
);

/// The ways to group the watched videos, each a large row; picking one
/// closes the modal with it.
class GroupingSheet extends StatelessWidget {
  static ValueKey<String> optionKey(HistoryGrouping grouping) =>
      ValueKey('history-grouping-${grouping.name}');

  final HistoryGrouping current;
  final List<HistoryGrouping> available;

  const GroupingSheet({
    super.key,
    required this.current,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final tiny = isTinyWidth(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(tiny ? 4 : 16, 8, tiny ? 4 : 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final grouping in available)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Option(
                key: optionKey(grouping),
                grouping: grouping,
                selected: grouping == current,
              ),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final HistoryGrouping grouping;
  final bool selected;

  const _Option({super.key, required this.grouping, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tiny = isTinyWidth(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(grouping),
          child: Padding(
            padding: EdgeInsets.all(tiny ? 8 : 12),
            child: Row(
              children: [
                if (!tiny) ...[
                  ExcludeSemantics(
                    child: Icon(
                      grouping.icon,
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grouping.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: selected ? scheme.onSecondaryContainer : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        grouping.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: selected
                              ? scheme.onSecondaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected && !tiny) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, color: scheme.onSecondaryContainer),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
