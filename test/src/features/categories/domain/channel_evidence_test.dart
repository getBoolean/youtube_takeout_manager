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
}
