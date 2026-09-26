import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/features/authentication/presentation/account_dialog.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/import_takeout.dart';

/// Shown until a takeout is imported: picks its zips, reviewing it in place
/// if there's anything to look over.
class TakeoutImportPrompt extends StatelessWidget {
  const TakeoutImportPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.upload_file, size: 80, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Import your Google Takeout data',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Select one or more takeout zip files',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 32),
        const ImportTakeout(idleLabel: 'Select zip files', prominent: true),
      ],
    );
  }
}

/// The saved takeout couldn't be read. The account dialog can remove it or
/// import another.
class TakeoutLoadFailed extends StatelessWidget {
  final Object error;

  const TakeoutLoadFailed({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'Failed to load saved data',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => showAccountDialog(context),
          child: const Text('Account', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
