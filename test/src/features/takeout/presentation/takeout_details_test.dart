import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_channel.dart';
import 'package:youtube_takeout_manager/src/features/takeout/presentation/other_accounts_section.dart';

TakeoutChannel _channel(String id, {int comments = 0, int liveChats = 0}) =>
    TakeoutChannel(
      channelId: id,
      isMain: id == 'UCa',
      listed: true,
      commentCount: comments,
      liveChatCount: liveChats,
    );

void main() {
  test('counts every channel and says when it was exported', () {
    final summary = TakeoutSummary(
      id: 'UCa',
      channels: [
        _channel('UCa', comments: 1000, liveChats: 1),
        _channel('UCb', comments: 234),
      ],
      latestExportAt: DateTime(2026, 4, 12, 12),
      countsKnown: true,
    );
    expect(
      describeTakeout(summary),
      '2 channels · 1,234 comments · 1 live chat · exported Apr 12, 2026',
    );
  });

  test('leaves out counts and dates it does not know', () {
    final summary = TakeoutSummary(
      id: 'UCa',
      channels: [_channel('UCa')],
      countsKnown: false,
    );
    expect(describeTakeout(summary), '');
  });
}
