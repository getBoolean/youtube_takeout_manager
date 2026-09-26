import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// A titled section of a dialog with one action that asks first, in place:
/// its button turns into [question] with Cancel and [confirmLabel]. How it
/// went shows under the button, not in a snack bar or another popup.
class ConfirmedActionSection extends StatefulWidget {
  final String title;
  final String description;
  final Widget? body;
  final IconData icon;
  final String actionLabel;
  final String question;
  final String confirmLabel;

  /// Shown once [onConfirm] is done.
  final String done;

  /// Shown, with the error, if [onConfirm] throws.
  final String failed;

  final Future<void> Function() onConfirm;

  const ConfirmedActionSection({
    super.key,
    required this.title,
    required this.description,
    this.body,
    required this.icon,
    required this.actionLabel,
    required this.question,
    required this.confirmLabel,
    required this.done,
    required this.failed,
    required this.onConfirm,
  });

  @override
  State<ConfirmedActionSection> createState() => _ConfirmedActionSectionState();
}

enum _Step { idle, asking, running }

class _ConfirmedActionSectionState extends State<ConfirmedActionSection> {
  var _step = _Step.idle;
  ({String message, bool error})? _outcome;

  Future<void> _confirm() async {
    setState(() => _step = _Step.running);
    ({String message, bool error}) outcome;
    try {
      await widget.onConfirm();
      outcome = (message: widget.done, error: false);
    } catch (e) {
      outcome = (message: '${widget.failed}: $e', error: true);
    }
    if (!mounted) return;
    setState(() {
      _step = _Step.idle;
      _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = _step == _Step.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (widget.body case final body?) ...[const SizedBox(height: 12), body],
        const SizedBox(height: 4),
        if (_step == _Step.idle) ...[
          TextButton.icon(
            onPressed: () => setState(() {
              _step = _Step.asking;
              _outcome = null;
            }),
            icon: isTinyWidth(context) ? null : Icon(widget.icon),
            label: Text(widget.actionLabel, textAlign: TextAlign.center),
          ),
          if (_outcome case (:final message, :final error))
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: error
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ] else ...[
          const SizedBox(height: 8),
          Text(widget.question, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: running
                    ? null
                    : () => setState(() => _step = _Step.idle),
                child: const Text('Cancel', textAlign: TextAlign.center),
              ),
              FilledButton(
                onPressed: running ? null : _confirm,
                child: Text(widget.confirmLabel, textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
