import 'package:flutter/material.dart';

/// One choice in an actions sheet: what picking it returns, and how it's
/// shown.
class SheetOption<T> {
  final T value;
  final IconData icon;
  final String title;
  final String? subtitle;

  const SheetOption(this.value, this.icon, this.title, [this.subtitle]);
}

/// Offers [options] in a bottom sheet, under [header] when there's one, e.g.
/// what they're for. Returns the value of the one picked, or null if the sheet
/// was dismissed.
Future<T?> showActionsSheet<T>(
  BuildContext context, {
  Widget? header,
  required List<SheetOption<T>> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: header,
              ),
              const Divider(height: 1),
            ],
            for (final option in options)
              ListTile(
                leading: Icon(option.icon),
                title: Text(option.title),
                subtitle: option.subtitle == null
                    ? null
                    : Text(option.subtitle!),
                onTap: () => Navigator.pop(context, option.value),
              ),
          ],
        ),
      ),
    ),
  );
}
