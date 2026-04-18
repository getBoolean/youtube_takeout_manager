import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/deletion_providers.dart';

/// AppBar action that toggles between selecting every id in [selectableIds]
/// and clearing the selection. The caller decides what "selectable" means
/// (e.g. eligible items for the current scope, already minus queued/failed).
class SelectAllToggleButton extends ConsumerWidget {
  final Set<String> selectableIds;

  const SelectAllToggleButton({super.key, required this.selectableIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(deletionSetProvider);
    final allSelected =
        selectableIds.isNotEmpty &&
        selectableIds.difference(selectedIds).isEmpty;

    return IconButton(
      icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
      tooltip: allSelected ? 'Deselect All' : 'Select All',
      onPressed: () {
        final notifier = ref.read(deletionSetProvider.notifier);
        if (allSelected) {
          notifier.clear();
        } else {
          notifier.addAll(selectableIds);
        }
      },
    );
  }
}
