// Frame-timing probe for the History screen, run against the real takeout.
// Opens History, then, grouped by day and by channel, flings the list,
// searches, filters Shorts and switches grouping, logging build and raster
// times for each. Signed out and without AI keys, so it fetches nothing and
// pays for nothing.
//
// flutter run -d windows --profile -t tool/history_probe.dart --dart-define-from-file=.env
// Debug mode is 5-10x slower; profile for representative numbers.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/app_effects.dart';
import 'package:youtube_takeout_manager/src/config/ai_config.dart';
import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/ai_keys.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_grouping.dart';
import 'package:youtube_takeout_manager/src/features/history/application/history_search_query.dart';
import 'package:youtube_takeout_manager/src/features/history/application/takeout_history_notifier.dart';
import 'package:youtube_takeout_manager/src/features/history/application/watch_filter_providers.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

final _router = AppRouter();
final _timings = <FrameTiming>[];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
  final container = ProviderContainer(
    overrides: [
      // Signed out: nothing is fetched, so no quota is spent.
      readSessionChannelIdProvider.overrideWith((ref) => null),
      // No AI keys: categorizing asks nothing, so nothing is paid for.
      aiKeysProvider.overrideWith((ref) async => AiKeys.none),
    ],
  );
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: _router.config(),
      ),
    ),
  );
  unawaited(_probe(container));
}

Future<void> _probe(ProviderContainer container) async {
  container.listen(appEffectsProvider, (_, _) {});
  container.listen(takeoutProvider, (_, _) {});
  final takeout = await container.read(takeoutProvider.future);
  if (takeout == null) {
    _log('No takeout is open; open one in the app first.');
    return;
  }
  await Future<void>.delayed(const Duration(seconds: 2));

  _timings.clear();
  final open = Stopwatch()..start();
  unawaited(_router.push(const HistoryRoute()));
  await _waitUntil(() => container.read(takeoutHistoryProvider).hasValue);
  final loaded = open.elapsedMilliseconds;
  await _waitUntil(() => _largestScrollable() != null);
  final firstList = open.elapsedMilliseconds;
  final history = container.read(takeoutHistoryProvider).value;
  _log(
    'history: ${history?.history.watches.length ?? 0} watched videos, '
    '${history?.watchedChannels.length ?? 0} channels, '
    '${history?.history.searches.length ?? 0} searches',
  );
  _log('loading took ${loaded}ms; the first list frame came at ${firstList}ms');
  await _settle('open');

  for (final grouping in [HistoryGrouping.day, HistoryGrouping.channel]) {
    final name = grouping.name;
    _timings.clear();
    container.read(historyGroupingProvider.notifier).set(grouping);
    await _settle('$name: switch grouping');

    _timings.clear();
    for (var i = 0; i < 3; i++) {
      await _fling(down: true);
      await _fling(down: false);
    }
    await _settle('$name: fling down and up 3 times');

    _timings.clear();
    container.read(historySearchQueryProvider.notifier).update('a');
    await _settle('$name: search "a"');
    _timings.clear();
    container.read(historySearchQueryProvider.notifier).update('');
    await _settle('$name: clear the search');

    _timings.clear();
    container.read(historyShortsFilterProvider.notifier).set(ShowFilter.only);
    await _settle('$name: only Shorts');
    _timings.clear();
    container.read(historyShortsFilterProvider.notifier).set(ShowFilter.all);
    await _settle('$name: Shorts with the rest');
  }
  _log('DONE');
}

/// The list's scroll position: the tallest vertical one on screen.
ScrollPosition? _largestScrollable() {
  ScrollPosition? found;
  void visit(Element e) {
    if (e is StatefulElement && e.state is ScrollableState) {
      final position = (e.state as ScrollableState).position;
      if (position.axis == Axis.vertical &&
          position.hasContentDimensions &&
          (found == null ||
              position.maxScrollExtent > found!.maxScrollExtent)) {
        found = position;
      }
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

/// Scrolls the list a long way, as a fling would.
Future<void> _fling({required bool down}) async {
  final position = _largestScrollable();
  if (position == null) return;
  final distance = position.viewportDimension * 40;
  final target = (position.pixels + (down ? distance : -distance)).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  await position.animateTo(
    target,
    duration: const Duration(milliseconds: 1200),
    curve: Curves.decelerate,
  );
}

/// Waits for things to settle, then logs the frames since the last clear.
Future<void> _settle(String label) async {
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  final frames = List.of(_timings);
  if (frames.isEmpty) {
    _log('$label: no frames');
    return;
  }
  String stats(int Function(FrameTiming f) of) {
    final values = [for (final f in frames) of(f)]..sort();
    final average = values.fold<int>(0, (s, v) => s + v) / values.length;
    final p90 = values[((values.length - 1) * 0.9).round()];
    return 'avg ${(average / 1000).toStringAsFixed(1)} '
        'p90 ${(p90 / 1000).toStringAsFixed(1)} '
        'worst ${(values.last / 1000).toStringAsFixed(1)}ms';
  }

  _log(
    '$label: ${frames.length} frames; '
    'build ${stats((f) => f.buildDuration.inMicroseconds)}; '
    'raster ${stats((f) => f.rasterDuration.inMicroseconds)}',
  );
}

Future<void> _waitUntil(bool Function() cond) async {
  while (!cond()) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void _log(String s) => debugPrint('[PROBE] $s');
