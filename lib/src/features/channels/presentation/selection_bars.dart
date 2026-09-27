import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/select_all_toggle_button.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/selection_action_bar.dart';
import '../application/selection_providers.dart';

/// The screen's app bar: [title], [leading] and [actions], or in selection
/// mode how many items are picked, with buttons to leave and to select all.
class SelectionAppBar extends ConsumerWidget implements PreferredSizeWidget {
  /// The channel whose screen it's on, or null on the channel list.
  final String? channelId;

  final Widget title;
  final Widget? leading;
  final List<Widget> actions;
  final double? titleSpacing;

  /// Shown in and out of selection mode.
  final PreferredSizeWidget? bottom;

  const SelectionAppBar({
    super.key,
    this.channelId,
    required this.title,
    this.leading,
    this.actions = const [],
    this.titleSpacing,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionMode = selectionModeProvider(channelId: channelId);
    if (!ref.watch(selectionMode)) {
      return AppBar(
        titleSpacing: titleSpacing,
        title: title,
        leading: leading,
        actions: actions,
        bottom: bottom,
      );
    }

    final count = ref.watch(
      selectedTargetsProvider(
        channelId: channelId,
      ).select((targets) => targets.count),
    );
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      title: Text('$count selected'),
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      leading: CloseButton(
        onPressed: () => ref.read(selectionMode.notifier).exit(),
      ),
      actions: [
        SelectAllToggleButton(
          selectableIds: ref.watch(selectableIdsProvider(channelId: channelId)),
        ),
      ],
      bottom: bottom,
    );
  }
}

/// The screen's bottom bars: in selection mode, once something is picked,
/// buttons to queue or remove it; otherwise [queueBar].
class SelectionBottomBar extends ConsumerWidget {
  /// The channel whose screen it's on, or null on the channel list.
  final String? channelId;

  final Widget? queueBar;

  const SelectionBottomBar({super.key, this.channelId, this.queueBar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionMode = selectionModeProvider(channelId: channelId);
    final selecting = ref.watch(selectionMode);
    final hasSelection = ref.watch(
      deletionSetProvider.select((s) => s.isNotEmpty),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBottomBar(
          visible: selecting && hasSelection,
          // Built even when nothing is picked, so it has content to animate
          // out; "0 items" only shows mid-animation.
          child: SelectionActionBar(
            selection: ref.watch(selectedTargetsProvider(channelId: channelId)),
            onExitSelection: () => ref.read(selectionMode.notifier).exit(),
          ),
        ),
        if (queueBar case final bar? when !selecting) bar,
      ],
    );
  }
}
