import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/utils/count_formatter.dart';
import '../application/categorization_progress.dart';

/// Tells screen readers once that the user's run started, with how many
/// channels it has, and once that it finished or stopped, never as each
/// channel is done, wherever in the app the user is: it goes around every
/// screen. A run dropped and started again, as when subscriptions arrive,
/// is one run: its end is told only once it's quiet for a moment.
class CategorizationAnnouncer extends ConsumerStatefulWidget {
  final Widget child;

  const CategorizationAnnouncer({super.key, required this.child});

  @override
  ConsumerState<CategorizationAnnouncer> createState() =>
      _CategorizationAnnouncerState();
}

class _CategorizationAnnouncerState
    extends ConsumerState<CategorizationAnnouncer> {
  /// How long a run must stay ended before its end is told.
  static const _quiet = Duration(seconds: 1);

  var _started = false;
  Timer? _ending;

  @override
  void initState() {
    super.initState();
    ref.listenManual(categorizationProgressProvider, _changed);
  }

  @override
  void dispose() {
    _ending?.cancel();
    super.dispose();
  }

  void _changed(RunProgress? previous, RunProgress next) {
    if (next.running && next.ai) {
      // Going again: the same run, as far as the user can tell.
      _ending?.cancel();
      _ending = null;
      if (!_started && next.total > 0) {
        _started = true;
        _announce(
          next.redo
              ? 'Categorizing ${formatCount(next.total, 'channel')} again '
                    'with updated prompts'
              : 'Categorizing ${formatCount(next.total, 'channel')} with AI',
        );
      }
    } else if ((previous?.running ?? false) && !next.running && _started) {
      _ending?.cancel();
      _ending = Timer(_quiet, () {
        _ending = null;
        _started = false;
        final ended = ref.read(categorizationProgressProvider);
        _announce(
          ended.interrupted
              ? 'Categorizing stopped: ${ended.done} of '
                    '${formatCount(ended.total, 'channel')} categorized'
              : '${formatCount(ended.total, 'channel')} categorized',
        );
      });
    }
  }

  void _announce(String message) {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
