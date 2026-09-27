import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/breakpoints.dart';
import '../../application/search_options_providers.dart';
import '../../domain/search_options_state.dart';

class SearchOptionsButton extends ConsumerWidget {
  const SearchOptionsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchOptionsProvider);
    final options = async.value ?? const SearchOptionsState();
    final notifier = ref.read(searchOptionsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final nonDefault = !options.isDefault;

    return IconButton(
      icon: Icon(Icons.tune, color: nonDefault ? colorScheme.primary : null),
      tooltip: 'Search options',
      onPressed: () async {
        final result = await showDialog<SearchOptionsState>(
          context: context,
          builder: (_) => SearchOptionsDialog(options: options),
        );
        if (result == null) return;
        await notifier.setExpandMatchedVideos(result.expandMatchedVideos);
        await notifier.setMatchGroupTitles(result.matchGroupTitles);
      },
    );
  }
}

/// Lets [options] be changed, returning the new values on Done or null if
/// cancelled.
class SearchOptionsDialog extends StatefulWidget {
  final SearchOptionsState options;

  const SearchOptionsDialog({super.key, required this.options});

  @override
  State<SearchOptionsDialog> createState() => _SearchOptionsDialogState();
}

class _SearchOptionsDialogState extends State<SearchOptionsDialog> {
  late SearchOptionsState _options = widget.options;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Title and buttons scroll too, and the margins shrink, so nothing
      // overflows in a tiny window. The content padding shrinks too: a
      // checkbox has a fixed minimum width, and the default padding leaves
      // it no room in the narrowest windows.
      scrollable: true,
      insetPadding: isCompactWidth(context) ? compactDialogInsets : null,
      contentPadding: isCompactWidth(context)
          ? const EdgeInsets.fromLTRB(8, 20, 8, 24)
          : null,
      title: const Text('Search options'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _options.expandMatchedVideos,
              onChanged: (v) => setState(
                () => _options = _options.copyWith(
                  expandMatchedVideos: v ?? false,
                ),
              ),
              title: const Text('Show all comments in matched videos'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _options.matchGroupTitles,
              onChanged: (v) => setState(
                () =>
                    _options = _options.copyWith(matchGroupTitles: v ?? false),
              ),
              title: const Text('Match video titles'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _options),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
