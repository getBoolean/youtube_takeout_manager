import 'package:flutter/material.dart';

import 'breakpoints.dart';

enum ActionEmphasis { text, outlined, tonal }

/// A labeled button that drops its label, keeping [label] as its tooltip, on
/// compact widths. It stays the same kind of button either way, so its shape,
/// colors and icon size don't change.
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

  static const _iconOnlyStyle = ButtonStyle(
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
    minimumSize: WidgetStatePropertyAll(Size(40, 40)),
  );

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (isCompactWidth(context)) {
      return Tooltip(
        message: label,
        child: switch (emphasis) {
          ActionEmphasis.text => TextButton(
            onPressed: onPressed,
            style: _iconOnlyStyle,
            child: iconWidget,
          ),
          ActionEmphasis.outlined => OutlinedButton(
            onPressed: onPressed,
            style: _iconOnlyStyle,
            child: iconWidget,
          ),
          ActionEmphasis.tonal => FilledButton.tonal(
            onPressed: onPressed,
            style: _iconOnlyStyle,
            child: iconWidget,
          ),
        },
      );
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
