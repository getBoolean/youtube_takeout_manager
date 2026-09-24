import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/search_options_providers.dart';
import '../../domain/search_options_state.dart';

class SearchOptionsMenuButton extends ConsumerWidget {
  const SearchOptionsMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchOptionsProvider);
    final options = async.value ?? const SearchOptionsState();
    final notifier = ref.read(searchOptionsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final nonDefault = !options.isDefault;

    return MenuAnchor(
      builder: (context, controller, _) {
        return IconButton(
          icon: Icon(
            Icons.tune,
            color: nonDefault ? colorScheme.primary : null,
          ),
          tooltip: 'Search options',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        CheckboxMenuButton(
          value: options.expandMatchedVideos,
          onChanged: (v) => notifier.setExpandMatchedVideos(v ?? false),
          child: const Text('Show all comments in matched videos'),
        ),
        CheckboxMenuButton(
          value: options.matchGroupTitles,
          onChanged: (v) => notifier.setMatchGroupTitles(v ?? false),
          child: const Text('Match video titles'),
        ),
      ],
    );
  }
}
