import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

WatchEntry _watch(String id, {String? title}) => WatchEntry(
  time: DateTime.utc(2026, 4, 12),
  kind: WatchKind.video,
  title: title ?? 'Video $id',
  url: 'https://www.youtube.com/watch?v=$id',
  channelTitle: 'A',
);

void main() {
  test('what an AI is told about a channel leaves out what it lacks', () {
    const evidence = ChannelEvidence(
      title: 'Speedy',
      topicLabels: ['Video game culture'],
      titles: ['Any% in 10 minutes'],
    );

    expect(evidence.toState(), {
      'channel': 'Speedy',
      'youtube_topics': ['Video game culture'],
      'watched_video_titles': ['Any% in 10 minutes'],
    });
  });

  test('video descriptions go with their titles', () {
    const evidence = ChannelEvidence(
      title: 'Speedy',
      titles: ['Any% in 10 minutes'],
      videoDescriptions: [
        (title: 'Any% in 10 minutes', description: 'A new record.'),
      ],
    );

    expect(evidence.toState()['watched_video_descriptions'], [
      {'title': 'Any% in 10 minutes', 'description': 'A new record.'},
    ]);
  });

  test('a long description is cut short for the AI', () {
    final evidence = ChannelEvidence(title: 'Wordy', description: 'x' * 2000);

    expect(
      (evidence.toState()['description']! as String).length,
      ChannelEvidence.maxDescription,
    );
  });

  test("the evidence takes its picks' titles and their cleaned "
      'descriptions, leaving out the ones not known', () {
    final watches = [_watch('a'), _watch('b'), _watch('c')];

    final evidence = buildEvidence(
      title: 'Speedy',
      picks: (titles: [0, 2], described: [0, 2]),
      watches: watches,
      descriptions: {'a': 'Fast. https://example.com', 'c': null},
    );

    expect(evidence.titles, ['Video a', 'Video c']);
    expect(evidence.videoDescriptions, [
      (title: 'Video a', description: 'Fast.'),
    ]);
  });

  group("the size of a channel's evidence, worked out without it", () {
    final description =
        'A run of the route, frame by frame, with every trick explained. '
        'https://example.com/route #speedrun #retro 0:00 Start 12:34 Finish '
        '${'More words about the run and the game. ' * 20}';
    final watches = [
      for (var i = 0; i < 60; i++)
        _watch('v$i', title: 'Run $i of the route: any% in record time'),
    ];
    final picks = (
      titles: [for (var i = 0; i < 60; i++) i],
      described: [for (var i = 0; i < 10; i++) i * 6],
    );

    int size() => evidenceSize(
      title: 'Speedy Runs',
      description: 'Speedruns of classic games. ' * 30,
      topics: 2,
      titles: [for (final i in picks.titles) watches[i].title],
      described: [
        for (final i in picks.described)
          (title: watches[i].title, description: description),
      ],
    );

    test('is close to its size as told to AI', () {
      final told = jsonEncode(
        buildEvidence(
          title: 'Speedy Runs',
          description: 'Speedruns of classic games. ' * 30,
          topicLabels: const ['Action game', 'Video game culture'],
          picks: picks,
          watches: watches,
          descriptions: {
            for (final i in picks.described) watches[i].videoId!: description,
          },
        ).toState(),
      ).length;

      expect(size(), inInclusiveRange(told * 0.8, told * 1.5));
    });

    test("is quick for a heavy viewer's 12,000 channels", () {
      final watch = Stopwatch()..start();
      for (var c = 0; c < 12000; c++) {
        size();
      }
      final took = watch.elapsedMilliseconds;

      // ignore: avoid_print
      print('Evidence sizes for 12,000 channels: ${took}ms');
      expect(took, lessThanOrEqualTo(_sizesBudget));
    });
  });
}

/// The evidence sizes of 12,000 channels may take this long, in
/// milliseconds: the first measured run's time (2026-10-07, in the test VM:
/// 32), three times over.
const _sizesBudget = 96;
