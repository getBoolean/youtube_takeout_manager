import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// A notice shown in place, e.g. inside a dialog instead of another popup.
/// Errors use the theme's error colors; others its tertiary ones.
class NoticeBanner extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final VoidCallback? onDismiss;
  final bool error;

  const NoticeBanner({
    super.key,
    required this.title,
    this.children = const [],
    this.actions = const [],
    this.onDismiss,
    this.error = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = error ? scheme.errorContainer : scheme.tertiaryContainer;
    final foreground = error
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              isTinyWidth(context) ? 8 : 12,
              onDismiss == null ? 12 : 4,
              onDismiss == null ? 12 : 4,
              actions.isEmpty ? 12 : 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final heading = Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    );
                    if (onDismiss == null) return heading;
                    final dismiss = IconButton(
                      onPressed: onDismiss,
                      tooltip: 'Dismiss',
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                    // Too narrow to share a line with the title.
                    if (constraints.maxWidth < 120) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: dismiss,
                          ),
                          heading,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: heading),
                        dismiss,
                      ],
                    );
                  },
                ),
                for (final child in children) ...[
                  const SizedBox(height: 8),
                  child,
                ],
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        for (final action in actions)
                          TextButtonTheme(
                            data: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: foreground,
                              ),
                            ),
                            child: action,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
