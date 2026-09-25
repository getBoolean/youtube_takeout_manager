import 'package:flutter/material.dart';

import '../domain/takeout_import_plan.dart';

/// Explains why picked takeout zips weren't imported. An account mismatch
/// names the channels involved, so a takeout from the wrong account can't
/// slip by unnoticed.
class ImportErrorDialog extends StatelessWidget {
  final TakeoutImportException error;

  const ImportErrorDialog({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = this.error;

    return AlertDialog(
      icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
      title: Text(
        error is TakeoutAccountMismatchException
            ? 'Different YouTube account'
            : "Couldn't import takeout",
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (error case TakeoutAccountMismatchException(
              :final expectedChannelIds,
              :final foundChannelIds,
            )) ...[
              const SizedBox(height: 16),
              _ChannelIds(label: 'Expected', channelIds: expectedChannelIds),
              const SizedBox(height: 12),
              _ChannelIds(
                label: 'In this takeout',
                channelIds: foundChannelIds,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Nothing was imported.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _ChannelIds extends StatelessWidget {
  final String label;
  final Set<String> channelIds;

  const _ChannelIds({required this.label, required this.channelIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        for (final id in channelIds)
          SelectableText(
            'youtube.com/channel/$id',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
      ],
    );
  }
}
