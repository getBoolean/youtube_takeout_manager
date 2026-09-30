import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/loaded_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';

WatchEntry _watch(String title, String? channel) => WatchEntry(
  time: DateTime.utc(2026, 4, 12),
  kind: WatchKind.video,
  title: title,
  url: 'https://www.youtube.com/watch?v=${title.hashCode}',
  channelTitle: channel,
);

void main() {
  test("each channel's most recent titles, newest first, up to a limit", () {
    final loaded = LoadedHistory.of(
      TakeoutHistory(
        watches: [
          _watch('a1', 'A'),
          _watch('b1', 'B'),
          _watch('a2', 'A'),
          _watch('gone', null),
          _watch('a3', 'A'),
        ],
      ),
    );

    final titles = recentTitlesByChannel(loaded, max: 2);

    expect(titles[loaded.channelIndexByKey['name:A']!], ['a1', 'a2']);
    expect(titles[loaded.channelIndexByKey['name:B']!], ['b1']);
  });

  test('what an AI is told about a channel leaves out what it lacks', () {
    const evidence = ChannelEvidence(
      title: 'Speedy',
      topicLabels: ['Video game culture'],
      recentTitles: ['Any% in 10 minutes'],
    );

    expect(evidence.toState(), {
      'channel': 'Speedy',
      'youtube_topics': ['Video game culture'],
      'watched_video_titles': ['Any% in 10 minutes'],
    });
  });

  test('a long description is cut short for the AI', () {
    final evidence = ChannelEvidence(title: 'Wordy', description: 'x' * 2000);

    expect(
      (evidence.toState()['description']! as String).length,
      ChannelEvidence.maxDescription,
    );
  });
}
