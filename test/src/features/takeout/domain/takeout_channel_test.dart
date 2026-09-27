import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_csv_encoder.dart';
import 'package:youtube_takeout_manager/src/features/takeout/data/takeout_summary_parser.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/own_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';

Comment _comment(String id, String channel) => Comment(
  commentId: id,
  channelId: channel,
  createdAt: DateTime.utc(2026),
  price: 0,
  rawCommentText: '{"text":"$id"}',
  displayText: id,
);

LiveChat _chat(String id, String channel) => LiveChat(
  liveChatId: id,
  channelId: channel,
  createdAt: DateTime.utc(2026),
  price: 0,
  rawText: '{"text":"$id"}',
  displayText: id,
);

/// A takeout from UCmain's Google account: UCalt wrote more than UCmain, and
/// UCextra wrote something without being in channel.csv. One row has no
/// Channel ID.
final _data = TakeoutData(
  comments: [
    _comment('m1', 'UCmain'),
    _comment('a1', 'UCalt'),
    _comment('a2', 'UCalt'),
    _comment('blank', ''),
    _comment('x1', 'UCextra'),
  ],
  liveChats: [_chat('a3', 'UCalt')],
  subscriptionsByChannelId: const {},
  ownChannels: const {
    'UCmain': OwnChannel(channelId: 'UCmain', title: 'Main', vanityName: 'mn'),
    'UCalt': OwnChannel(channelId: 'UCalt', title: 'Alt'),
  },
  latestExportAt: DateTime.utc(2026, 4, 12),
);

void main() {
  group('takeoutChannelsOf', () {
    test('lists every channel, main first, then by how much they wrote', () {
      final channels = takeoutChannelsOf(_data, takeoutId: 'UCmain');

      expect(channels.map((c) => c.channelId), ['UCmain', 'UCalt', 'UCextra']);
      expect(channels.map((c) => c.isMain), [true, false, false]);
      expect(channels.map((c) => c.listed), [true, true, false]);
      expect(channels.first.title, 'Main');
      expect(channels.first.vanityName, 'mn');
    });

    test('counts rows without a Channel ID as the main channel', () {
      final main = takeoutChannelsOf(_data, takeoutId: 'UCmain').first;
      expect(main.commentCount, 2);
      expect(main.liveChatCount, 0);
    });

    test('with several listed channels the takeout ID is the main one', () {
      final channels = takeoutChannelsOf(_data, takeoutId: 'UCalt');
      expect(channels.first.channelId, 'UCalt');
      expect(channels.first.isMain, isTrue);
    });

    test('a single listed channel is the main one', () {
      final data = _data.copyWith(
        ownChannels: const {'UCalt': OwnChannel(channelId: 'UCalt')},
      );
      expect(
        takeoutChannelsOf(data, takeoutId: 'UCmain').first.channelId,
        'UCalt',
      );
    });

    test('data saved without channel files lists its authors', () {
      final data = _data.copyWith(ownChannels: const {});
      final channels = takeoutChannelsOf(data, takeoutId: 'UCmain');
      expect(channels.map((c) => c.channelId), ['UCmain', 'UCalt', 'UCextra']);
      expect(channels.every((c) => !c.listed), isTrue);
    });
  });

  test('a summary read from the saved summary files matches the full data', () {
    final files = encodeTakeoutCsvs(_data);
    final summaryFiles = {
      for (final MapEntry(:key, :value) in files.entries)
        if (isTakeoutSummaryPath(key)) key: value,
    };
    // Only small files: not the comments or live chats themselves.
    expect(summaryFiles.keys.where((p) => p.contains('comments/')), isEmpty);

    final summary = parseTakeoutSummary('UCmain', summaryFiles);

    expect(summary.id, 'UCmain');
    expect(summary.countsKnown, isTrue);
    expect(summary.latestExportAt, DateTime.utc(2026, 4, 12));
    expect(summary.channels, takeoutChannelsOf(_data, takeoutId: 'UCmain'));
    expect(summary.main.channelId, 'UCmain');
    expect(summary.channelIds, {'UCmain', 'UCalt', 'UCextra'});
  });

  test('a summary of data saved before summaries is just its ID', () {
    final summary = parseTakeoutSummary('UCold', const {});
    expect(summary.channelIds, {'UCold'});
    expect(summary.countsKnown, isFalse);
    expect(summary.main.isMain, isTrue);
  });

  group('resolveViewedChannelId', () {
    final channels = takeoutChannelsOf(_data, takeoutId: 'UCmain');

    test('keeps the remembered channel', () {
      expect(resolveViewedChannelId(channels, remembered: 'UCalt'), 'UCalt');
    });

    test('falls back to the main channel', () {
      expect(resolveViewedChannelId(channels, remembered: 'UCgone'), 'UCmain');
      expect(resolveViewedChannelId(channels), 'UCmain');
    });

    test('is null without channels', () {
      expect(resolveViewedChannelId(const []), isNull);
    });
  });

  group('onlyChannel', () {
    test("keeps only one channel's items", () {
      final alt = onlyChannel(_data, 'UCalt', mainChannelId: 'UCmain');
      expect(alt.comments.map((c) => c.commentId), ['a1', 'a2']);
      expect(alt.liveChats.map((c) => c.liveChatId), ['a3']);
    });

    test('gives the main channel rows without a Channel ID', () {
      final main = onlyChannel(_data, 'UCmain', mainChannelId: 'UCmain');
      expect(main.comments.map((c) => c.commentId), ['m1', 'blank']);
    });

    test('returns the same data when nothing is filtered out', () {
      final single = TakeoutData(
        comments: [_comment('m1', 'UCmain')],
        liveChats: const [],
        subscriptionsByChannelId: const {},
      );
      expect(onlyChannel(single, 'UCmain', mainChannelId: 'UCmain'), single);
    });
  });
}
