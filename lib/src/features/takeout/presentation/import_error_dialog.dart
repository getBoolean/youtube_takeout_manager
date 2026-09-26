import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_identity.dart';
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
              :final titlesById,
            )) ...[
              const SizedBox(height: 16),
              _ChannelIds(
                label: 'Expected',
                channelIds: expectedChannelIds,
                titlesById: titlesById,
              ),
              const SizedBox(height: 12),
              _ChannelIds(
                label: 'In this takeout',
                channelIds: foundChannelIds,
                titlesById: titlesById,
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
  final Map<String, String> titlesById;

  const _ChannelIds({
    required this.label,
    required this.channelIds,
    required this.titlesById,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        for (final id in channelIds)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ChannelIdentity(channelId: id, title: titlesById[id]),
          ),
      ],
    );
  }
}
