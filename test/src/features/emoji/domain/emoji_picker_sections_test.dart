import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/domain/channel_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_picker_sections.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/emoji_use.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/picker_emoji.dart';
import 'package:youtube_takeout_manager/src/features/emoji/domain/unicode_emoji.dart';

ChannelEmoji _custom(String name, {String channelId = 'UC1'}) => ChannelEmoji(
  key: name,
  url: 'https://yt3.ggpht.com/$name',
  name: name,
  channelId: channelId,
  usageCount: 1,
  resolved: true,
);

UnicodeEmoji _standard(
  String emoji,
  List<String> shortNames,
  String name,
  UnicodeEmojiCategory category,
) => UnicodeEmoji(
  emoji: emoji,
  shortNames: shortNames,
  name: name,
  category: category,
);

final _shortsad = _custom('shortsad');
final _shyWave = _custom('shy_wave');
final _groups = [
  ChannelEmojiGroup(
    channelId: 'UC1',
    channelTitle: 'Shylily',
    emojis: [_shortsad, _shyWave],
  ),
  const ChannelEmojiGroup(channelId: 'UC2', emojis: []),
  ChannelEmojiGroup(
    channelId: 'UC3',
    emojis: [_custom('gg', channelId: 'UC3')],
  ),
];

final _fire = _standard('🔥', ['fire'], 'fire', UnicodeEmojiCategory.nature);
final _grinning = _standard(
  '😀',
  ['grinning'],
  'grinning face',
  UnicodeEmojiCategory.people,
);
final _redCircle = _standard(
  '🔴',
  ['red_circle'],
  'large red circle',
  UnicodeEmojiCategory.symbols,
);

EmojiUse _use(String id) =>
    EmojiUse(id: id, count: 1, lastUsed: DateTime(2026));

/// Each section as its title and the `:name:`s in it.
List<String> _shown(List<EmojiPickerSection> sections) => [
  for (final section in sections)
    '${section.title}: ${section.emojis.map((e) => e.token).join(' ')}',
];

void main() {
  final content = EmojiPickerContent(
    groups: _groups,
    standardEmojis: [_fire, _grinning, _redCircle],
  );

  test('channels, then standard emojis by category', () {
    expect(_shown(content.sections(const [])), [
      'Shylily: :shortsad: :shy_wave:',
      'UC3: :gg:',
      'People: :grinning:',
      'Nature: :fire:',
      'Symbols: :red_circle:',
    ]);
  });

  test('sections say what they are', () {
    final sections = content.sections([_use('u:🔥')]);
    expect(sections.map((s) => s.id), [
      frequentSectionId,
      'UC1',
      'UC3',
      UnicodeEmojiCategory.people,
      UnicodeEmojiCategory.nature,
      UnicodeEmojiCategory.symbols,
    ]);
    expect(sections[0], isA<FrequentEmojiSection>());
    expect((sections[1] as ChannelEmojiSection).channel, _groups[0]);
    expect(
      (sections[3] as CategoryEmojiSection).category,
      UnicodeEmojiCategory.people,
    );
  });

  test('Frequently Used comes first, with emojis this picker offers', () {
    final sections = content.sections([
      _use('u:🔥'),
      _use('c:gone'),
      _use('c:shortsad'),
      _use('u:😢'),
    ]);
    expect(_shown(sections).first, 'Frequently Used: :fire: :shortsad:');
  });

  test('Frequently Used shows at most 16', () {
    final many = EmojiPickerContent(
      groups: [
        ChannelEmojiGroup(
          channelId: 'UC1',
          emojis: [for (var i = 0; i < 20; i++) _custom('e$i')],
        ),
      ],
      standardEmojis: const [],
    );
    final sections = many.sections([
      for (var i = 0; i < 20; i++) _use('c:e$i'),
    ]);
    expect(sections.first.emojis, hasLength(16));
  });

  group('filterEmojiPickerSections', () {
    final all = content.sections([_use('u:🔥')]);
    List<String> filter(String text) =>
        _shown(filterEmojiPickerSections(all, text));

    test('keeps everything without a filter', () {
      expect(filterEmojiPickerSections(all, '  '), all);
    });

    test('matches channel emoji names', () {
      expect(filter('SHORT'), ['Shylily: :shortsad:']);
    });

    test('matches standard short names and Unicode names', () {
      expect(filter('fir'), ['Nature: :fire:']);
      expect(filter('red_circ'), ['Symbols: :red_circle:']);
      expect(filter('grinning-face'), ['People: :grinning:']);
    });

    test('ignores colons', () {
      expect(filter(':shy_wave:'), ['Shylily: :shy_wave:']);
    });

    test('hides Frequently Used and empty sections', () {
      expect(filter('fire'), ['Nature: :fire:']);
      expect(filter('nothing'), isEmpty);
    });
  });

  test('picker emojis are the ones offered', () {
    final sections = content.sections(const []);
    expect(sections.first.emojis.first, CustomPickerEmoji(_shortsad));
    expect(sections.last.emojis.single, UnicodePickerEmoji(_redCircle));
  });
}
