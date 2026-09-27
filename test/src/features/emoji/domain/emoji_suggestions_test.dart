import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/channel_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_suggestions.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/picker_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';

ChannelEmoji _custom(String name, int usageCount) => ChannelEmoji(
  key: name,
  url: 'https://yt3.ggpht.com/$name',
  name: name,
  channelId: 'UC1',
  usageCount: usageCount,
  resolved: true,
);

UnicodeEmoji _standard(String emoji, List<String> shortNames) => UnicodeEmoji(
  emoji: emoji,
  shortNames: shortNames,
  name: shortNames.first,
  category: UnicodeEmojiCategory.symbols,
);

final _shortsad = _custom('shortsad', 3);
final _shypraise = _custom('shypraise', 1);
final _customFire = _custom('fire', 2);

final _heartEyes = _standard('😍', ['heart_eyes']);
final _heart = _standard('❤️', ['heart']);
final _fire = _standard('🔥', ['fire', 'flame']);
final _fish = _standard('🐟', ['fish']);
final _campfire = _standard('🏕', ['camping', 'campfire']);

/// What a suggestion list shows: `:name:` and whether it's a channel's.
List<String> _shown(List<PickerEmoji> suggestions) => [
  for (final emoji in suggestions)
    switch (emoji) {
      CustomPickerEmoji() => 'channel ${emoji.token}',
      UnicodePickerEmoji() => '${emoji.insertText} ${emoji.token}',
    },
];

void main() {
  List<String> rank(
    String fragment, {
    List<ChannelEmoji>? custom,
    List<UnicodeEmoji>? standard,
    bool includeStandard = true,
  }) => _shown(
    rankEmojiSuggestions(
      fragment,
      custom: custom ?? [_shortsad, _shypraise],
      standard: standard ?? [_heartEyes, _heart, _fire, _fish, _campfire],
      includeStandard: includeStandard,
    ),
  );

  test('offers only names containing the fragment', () {
    expect(rank('sho'), ['channel :shortsad:']);
    expect(rank('fi'), ['🔥 :fire:', '🐟 :fish:', '🏕 :campfire:']);
  });

  test('ranks channel emojis by use', () {
    expect(rank('sh', custom: [_shypraise, _shortsad]), [
      'channel :shortsad:',
      'channel :shypraise:',
      '🐟 :fish:',
    ]);
  });

  test('exact, then prefix, then other matches', () {
    expect(
      rank('fire', custom: [_custom('firefly', 9), _custom('bonfire', 9)]),
      ['🔥 :fire:', 'channel :firefly:', 'channel :bonfire:', '🏕 :campfire:'],
    );
  });

  test('a channel emoji comes before a standard one of the same name', () {
    expect(rank('fire', custom: [_customFire]), [
      'channel :fire:',
      '🔥 :fire:',
      '🏕 :campfire:',
    ]);
  });

  test('shortest standard names first', () {
    expect(rank('hear'), ['❤️ :heart:', '😍 :heart_eyes:']);
  });

  test('shows the alias that matched', () {
    expect(rank('flam'), ['🔥 :flame:']);
    expect(rank('campf'), ['🏕 :campfire:']);
  });

  test(':_name leaves standard emojis out', () {
    expect(rank('fire', custom: [_customFire], includeStandard: false), [
      'channel :fire:',
    ]);
  });

  test('offers only the given standard emojis', () {
    expect(rank('fi', standard: [_fire]), ['🔥 :fire:']);
  });

  test('offers at most $maxEmojiSuggestions', () {
    final many = [for (var i = 0; i < 20; i++) _custom('sh$i', i)];
    final suggestions = rankEmojiSuggestions(
      'sh',
      custom: many,
      standard: const [],
    );
    expect(suggestions, hasLength(maxEmojiSuggestions));
    expect(suggestions.first, CustomPickerEmoji(many.last));
  });
}
