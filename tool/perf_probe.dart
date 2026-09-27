// Frame-timing probe for the channel detail screen, run against the real
// takeout data. Opens the largest channels, switches to the live chat tab,
// then reopens them and logs build/raster times and widget counts.
//
// flutter run -d windows -t tool/perf_probe.dart --dart-define-from-file=.env
// Add --profile for representative numbers; debug mode is 5-10x slower.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/app_effects.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/grouped_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/takeout_notifier.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/routing/app_router.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

final _router = AppRouter();
final _timings = <FrameTiming>[];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
  final container = ProviderContainer();
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
  // Keep data providers alive and wait for them.
  container.listen(takeoutProvider, (_, _) {});
  container.listen(videoMetadataProvider, (_, _) {});
  container.listen(channelsProvider, (_, _) {});
  await container.read(takeoutProvider.future);
  await _waitUntil(() => container.read(videoMetadataProvider).hasValue);
  await Future<void>.delayed(const Duration(seconds: 3));
  unawaited(_router.push(const ChannelListRoute()));
  await _settle('channel list');

  final channels = container
      .read(channelsProvider)
      .where((c) => c.commentCount > 0 && c.liveChatCount > 0)
      .toList();
  _log('channels with both tabs: ${channels.length}');
  final picks = [
    ...channels.take(3),
    ...channels.skip(channels.length ~/ 2).take(2),
  ];

  for (final c in picks.take(3)) {
    final sw = Stopwatch()..start();
    final sub1 = container.listen(
      filteredGroupedChannelInteractionsProvider(
        QueueItemKind.liveChat,
        c.channelId,
      ),
      (_, _) {},
    );
    final t1 = sw.elapsedMicroseconds;
    final sub2 = container.listen(
      filteredGroupedChannelInteractionsProvider(
        QueueItemKind.comment,
        c.channelId,
      ),
      (_, _) {},
    );
    _log(
      'providers ${c.channelId}: liveChatGroups=${t1 ~/ 1000}ms commentGroups=${(sw.elapsedMicroseconds - t1) ~/ 1000}ms groups=${sub1.read().length}/${sub2.read().length}',
    );
    sub1.close();
    sub2.close();
  }

  for (final pass in ['first', 'second']) {
    for (final c in picks) {
      final label =
          '$pass open ${c.channelId} (c=${c.commentCount}, lc=${c.liveChatCount})';
      unawaited(_router.push(ChannelDetailRoute(channelId: c.channelId)));
      await _settle('$label: open');
      _log('  widgets after open: ${_countWidgets()}');
      _findTabBar()?.controller?.animateTo(1);
      await _settle('$label: live chat tab');
      _log('  widgets after tab: ${_countWidgets()}');
      _router.maybePop();
      await _settle('$label: pop');
    }
  }
  _log('DONE');
}

TabBar? _findTabBar() {
  TabBar? found;
  void visit(Element e) {
    if (found != null) return;
    if (e.widget is TabBar) {
      found = e.widget as TabBar;
      return;
    }
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return found;
}

Future<void> _settle(String label) async {
  _timings.clear();
  final sw = Stopwatch()..start();
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  final frames = List.of(_timings);
  if (frames.isEmpty) {
    _log('$label: no frames');
    return;
  }
  int ms(Duration d) => d.inMilliseconds;
  final worstBuild = frames
      .map((f) => ms(f.buildDuration))
      .reduce((a, b) => a > b ? a : b);
  final worstRaster = frames
      .map((f) => ms(f.rasterDuration))
      .reduce((a, b) => a > b ? a : b);
  final totalBuild = frames.fold<int>(0, (s, f) => s + ms(f.buildDuration));
  final slow = frames
      .where((f) => ms(f.totalSpan) > 32)
      .map((f) => '${ms(f.buildDuration)}/${ms(f.rasterDuration)}')
      .take(6);
  _log(
    '$label: frames=${frames.length} worstBuild=${worstBuild}ms '
    'worstRaster=${worstRaster}ms totalBuild=${totalBuild}ms '
    'slow(build/raster)=${slow.join(' ')} [${sw.elapsedMilliseconds}ms]',
  );
}

Future<void> _waitUntil(bool Function() cond) async {
  while (!cond()) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void _log(String s) => debugPrint('[PROBE] $s');

String _countWidgets() {
  const names = {
    'CommentTile',
    'LiveChatTile',
    'SuperChatCard',
    'VideoGroupHeader',
    'EmojiPreview',
    'Cue',
    'Actor',
    'HighlightedText',
    'Checkbox',
    'IconButton',
    'Tooltip',
  };
  final counts = <String, int>{};
  var total = 0;
  void visit(Element e) {
    total++;
    final n = e.widget.runtimeType.toString().split('<').first;
    if (names.contains(n)) counts[n] = (counts[n] ?? 0) + 1;
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return 'elements=$total $counts';
}
