import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import '../domain/interaction_status.dart';
import 'interaction_status_style.dart';

/// The list tile a comment or live chat shows in: a leading icon for its
/// status, or [icon] while active, that turns into a checkbox in selection
/// mode. Deleted items are dimmed.
class InteractionTile extends StatelessWidget {
  final InteractionStatus status;
  final IconData icon;
  final Color iconColor;
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;
  final bool isSelected;
  final bool selectionMode;

  /// Also dims queued and failed items, for lists that don't say why they
  /// can't be picked.
  final bool dimUnselectable;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const InteractionTile({
    super.key,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.isSelected,
    required this.selectionMode,
    this.dimUnselectable = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final leadingIcon = status.icon ?? icon;
    final leadingColor =
        status.color(Theme.of(context).colorScheme) ?? iconColor;
    final dimmed =
        status == InteractionStatus.deleted ||
        (dimUnselectable && !status.isSelectable);

    return AnimatedOpacity(
      opacity: dimmed ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: Cue.onChange(
            value: selectionMode,
            motion: premiumSpring(context),
            acts: const [OpacityAct.fadeIn()],
            child: Center(
              child: selectionMode
                  ? Checkbox(
                      key: const ValueKey('checkbox'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: isSelected,
                      onChanged: (_) => onTap(),
                    )
                  : Cue.onChange(
                      key: const ValueKey('icon'),
                      value: leadingIcon.codePoint,
                      motion: premiumSpring(context),
                      acts: const [OpacityAct.fadeIn(), ScaleAct(from: 0.7)],
                      child: Icon(
                        leadingIcon,
                        key: ValueKey(leadingIcon.codePoint),
                        color: leadingColor,
                      ),
                    ),
            ),
          ),
        ),
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        selected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
