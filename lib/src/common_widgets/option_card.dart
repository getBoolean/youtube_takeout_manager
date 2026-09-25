import 'package:flutter/material.dart';

/// A tappable card for one choice in a dialog.
///
/// With [selected] set, it's one of a set of choices confirmed by a separate
/// button and shows a radio indicator. Without it, tapping acts right away
/// and it shows a chevron. A null [onTap] disables it.
class OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final bool? selected;
  final VoidCallback? onTap;

  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onTap != null;
    final isSelected = selected ?? false;
    final foreground = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);
    // In a very narrow window, drop the icons before the text runs out of
    // room. Goes by the window, not a LayoutBuilder, since dialogs size
    // their content by its intrinsic width.
    final windowWidth = MediaQuery.sizeOf(context).width;
    final showIcon = windowWidth >= 280;
    final showIndicator = windowWidth >= 200;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: Material(
        color: isSelected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(showIcon ? 16 : 12),
            child: Row(
              children: [
                if (showIcon) ...[
                  Icon(icon, color: enabled ? scheme.primary : foreground),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: foreground,
                            ),
                          ),
                          ?badge,
                        ],
                      ),
                      if (subtitle case final subtitle?) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: enabled
                                ? scheme.onSurfaceVariant
                                : foreground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showIndicator) ...[
                  const SizedBox(width: 8),
                  if (selected != null)
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected ? scheme.primary : foreground,
                    )
                  else
                    Icon(Icons.chevron_right, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
