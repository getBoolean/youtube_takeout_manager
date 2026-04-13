import 'package:flutter/material.dart';

class ImportProgressIndicator extends StatelessWidget {
  final String message;

  const ImportProgressIndicator({
    super.key,
    this.message = 'Importing takeout data...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
