import 'package:flutter/material.dart';

import 'breakpoints.dart';

enum ActionEmphasis { text, outlined, tonal }

/// A labeled button that shrinks to an icon button, with [label] as its
/// tooltip, on compact widths.
class AdaptiveActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ActionEmphasis emphasis;

  const AdaptiveActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasis = ActionEmphasis.text,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (isCompactWidth(context)) {
      return switch (emphasis) {
        ActionEmphasis.text => IconButton(
          icon: iconWidget,
          tooltip: label,
          onPressed: onPressed,
        ),
        ActionEmphasis.outlined => IconButton.outlined(
          icon: iconWidget,
          tooltip: label,
          onPressed: onPressed,
        ),
        ActionEmphasis.tonal => IconButton.filledTonal(
          icon: iconWidget,
          tooltip: label,
          onPressed: onPressed,
        ),
      };
    }
    final labelWidget = Text(label);
    return switch (emphasis) {
      ActionEmphasis.text => TextButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: labelWidget,
      ),
      ActionEmphasis.outlined => OutlinedButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: labelWidget,
      ),
      ActionEmphasis.tonal => FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: iconWidget,
        label: labelWidget,
      ),
    };
  }
}
