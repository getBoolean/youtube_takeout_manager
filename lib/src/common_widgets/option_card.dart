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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: enabled ? scheme.primary : foreground,
                ),
                const SizedBox(width: 16),
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
            ),
          ),
        ),
      ),
    );
  }
}
