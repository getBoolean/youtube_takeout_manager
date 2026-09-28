import 'package:flutter/material.dart';

/// A small rounded label, e.g. "Viewing" beside a name. [icon], [background]
/// and [foreground] set a badge apart from the others around it.
class LabelBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  const LabelBadge(
    this.label, {
    super.key,
    this.icon,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = foreground ?? scheme.onSecondaryContainer;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: color);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: icon == null
            ? Text(label, style: style)
            : Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(icon, size: 12, color: color),
                      ),
                    ),
                    TextSpan(text: label),
                  ],
                ),
                style: style,
              ),
      ),
    );
  }
}
