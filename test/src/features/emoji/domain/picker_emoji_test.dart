import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/channel_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/picker_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';

const _shortsad = ChannelEmoji(
  key: 'k1',
  url: 'https://yt3.ggpht.com/k1',
  name: 'shortsad',
  channelId: 'UC1',
  usageCount: 3,
  resolved: true,
);
const _fire = UnicodeEmoji(
  emoji: '🔥',
  shortNames: ['fire', 'flame'],
  name: 'fire',
  category: UnicodeEmojiCategory.nature,
);

void main() {
  PickerEmoji? find(String usageId) => pickerEmojiForUse(
    usageId,
    customByKey: {_shortsad.key: _shortsad},
    standardByEmoji: {_fire.emoji: _fire},
  );

  test('finds the emoji a usage id was recorded for', () {
    expect(
      find(const CustomPickerEmoji(_shortsad).usageId),
      const CustomPickerEmoji(_shortsad),
    );
    expect(
      find(UnicodePickerEmoji(_fire, 'flame').usageId),
      UnicodePickerEmoji(_fire),
    );
  });

  test('keeps the ids already saved on devices', () {
    expect(const CustomPickerEmoji(_shortsad).usageId, 'c:k1');
    expect(UnicodePickerEmoji(_fire).usageId, 'u:🔥');
    expect(find('c:k1'), const CustomPickerEmoji(_shortsad));
    expect(find('u:🔥'), UnicodePickerEmoji(_fire));
  });

  test('skips emojis that are not offered', () {
    for (final id in ['c:gone', 'u:😀', 'k1', '🔥', '', 'x:k1']) {
      expect(find(id), isNull, reason: id);
    }
  });
}
