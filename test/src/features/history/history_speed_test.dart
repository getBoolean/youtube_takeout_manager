import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/prompt_videos.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_csv_codec.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_engine.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/channel_groups.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_days.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_wire.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_filters.dart';

import 'synthetic_history.dart';

/// The fastest of three runs of [work], in milliseconds.
Future<int> _best(Future<void> Function() work) async {
  var best = 1 << 30;
  for (var i = 0; i < 3; i++) {
    final watch = Stopwatch()..start();
    await work();
    best = watch.elapsedMilliseconds < best ? watch.elapsedMilliseconds : best;
  }
  return best;
}

/// What each step may take, in milliseconds, on a history the size of a
/// heavy viewer's: the first measured run's times (2026-10-05, in the test
/// VM: load 1256, search 145, channels 96, by channel 9, by day 57,
/// counts 10, picks 87), three times over, and at least 50 (ruling 13).
const _budgets = {
  'load': 3768,
  'search': 435,
  'channels': 288,
  'by channel': 50,
  'by day': 171,
  'counts': 50,
  'picks': 261,
};

void main() {
  late final Map<String, dynamic> files;
  late final LoadedHistory loaded;
  // Searched and counted as the app does, through the History worker's
  // wire, in-process.
  final engine = LocalHistoryEngine();

  setUpAll(() async {
    files = syntheticHistoryFiles();
    loaded = loadSavedHistory(files.cast());
    await engine.load(files.cast());
  });

  final measured = <String, int>{};

  Future<void> within(String step, Future<void> Function() work) async {
    final took = await _best(work);
    measured[step] = took;
    final budget = _budgets[step];
    if (budget != null) {
      expect(took, lessThanOrEqualTo(budget), reason: '$step took ${took}ms');
    }
  }

  tearDownAll(() {
    // ignore: avoid_print
    print('History speed (ms): $measured');
  });

  test('a heavy history loads in time', () async {
    expect(loaded.history.watches, hasLength(64000));
    await within('load', () async => loadSavedHistory(files.cast()));
  });

  test('a search narrows it in time', () async {
    await within('search', () async {
      await engine.search(const HistoryQuery(query: 'a'), 1);
    });
  });

  test('picking channels narrows it in time', () async {
    final picked = {
      for (final watched in loaded.watchedChannels.take(10))
        watched.channel.key: watched.channel,
    };
    await within('channels', () async {
      final mask = buildChannelMask(
        channels: loaded.watchedChannels,
        subscribedKeys: const {},
        subscription: SubscriptionFilter.all,
        selection: ChannelSelection(channels: picked),
      );
      await engine.search(HistoryQuery(channelMask: mask!.flags), 1);
    });
  });

  test('grouping by channel and by day takes no time to speak of', () async {
    final all = [for (var i = 0; i < loaded.history.watches.length; i++) i];
    await within('by channel', () async {
      groupByChannel(
        channels: loaded.watchedChannels,
        watchChannelIndex: loaded.watchChannelIndex,
        watchIndices: all,
      );
    });
    await within('by day', () async {
      monthsOf(groupByDay(all, loaded.watchDayKeys));
    });
  });

  test("the viewing mix's counts come in time", () async {
    await within('counts', () async {
      await engine.channelWatchCounts(shorts: ShowFilter.hide);
    });
  });

  test("the videos AI is told about are picked in time", () async {
    await within('picks', () async => pickPromptVideos(loaded));
  });
}
