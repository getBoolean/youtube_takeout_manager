import 'channel_emoji.dart';
import 'emoji_use.dart';
import 'picker_emoji.dart';
import 'unicode_emoji.dart';

/// [EmojiPickerSection.id] of Frequently Used.
const frequentSectionId = #frequent;

/// Most emojis Frequently Used shows.
const maxFrequentShown = 16;

final _nameSeparators = RegExp('[_-]');

/// One section of the emoji picker: Frequently Used, a channel's emojis or a
/// standard emoji category.
sealed class EmojiPickerSection {
  final List<PickerEmoji> emojis;

  const EmojiPickerSection(this.emojis);

  /// Tells sections apart across rebuilds: [frequentSectionId], a channel id
  /// or a [UnicodeEmojiCategory].
  Object get id;
  String get title;

  EmojiPickerSection _withEmojis(List<PickerEmoji> emojis);
}

final class FrequentEmojiSection extends EmojiPickerSection {
  const FrequentEmojiSection(super.emojis);

  @override
  Object get id => frequentSectionId;
  @override
  String get title => 'Frequently Used';

  @override
  FrequentEmojiSection _withEmojis(List<PickerEmoji> emojis) =>
      FrequentEmojiSection(emojis);
}

final class ChannelEmojiSection extends EmojiPickerSection {
  final ChannelEmojiGroup channel;

  const ChannelEmojiSection(this.channel, super.emojis);

  @override
  Object get id => channel.channelId;
  @override
  String get title => channel.displayTitle;

  @override
  ChannelEmojiSection _withEmojis(List<PickerEmoji> emojis) =>
      ChannelEmojiSection(channel, emojis);
}

final class CategoryEmojiSection extends EmojiPickerSection {
  final UnicodeEmojiCategory category;

  const CategoryEmojiSection(this.category, super.emojis);

  @override
  Object get id => category;
  @override
  String get title => category.label;

  @override
  CategoryEmojiSection _withEmojis(List<PickerEmoji> emojis) =>
      CategoryEmojiSection(category, emojis);
}

/// What an emoji picker offers: one section per channel in [groups] with
/// emojis, then [standardEmojis] by category. Built once per picker content.
class EmojiPickerContent {
  final List<ChannelEmojiSection> _channelSections;
  final List<CategoryEmojiSection> _standardSections;
  final Map<String, ChannelEmoji> _customByKey;
  final Map<String, UnicodeEmoji> _standardByEmoji;

  EmojiPickerContent._(
    this._channelSections,
    this._standardSections,
    this._customByKey,
    this._standardByEmoji,
  );

  factory EmojiPickerContent({
    required List<ChannelEmojiGroup> groups,
    required List<UnicodeEmoji> standardEmojis,
  }) {
    final byCategory = <UnicodeEmojiCategory, List<PickerEmoji>>{};
    for (final emoji in standardEmojis) {
      byCategory
          .putIfAbsent(emoji.category, () => [])
          .add(UnicodePickerEmoji(emoji));
    }
    return EmojiPickerContent._(
      [
        for (final group in groups)
          if (group.emojis.isNotEmpty)
            ChannelEmojiSection(group, [
              for (final emoji in group.emojis) CustomPickerEmoji(emoji),
            ]),
      ],
      [
        for (final category in UnicodeEmojiCategory.values)
          if (byCategory[category] case final emojis?)
            CategoryEmojiSection(category, emojis),
      ],
      {
        for (final group in groups)
          for (final emoji in group.emojis) emoji.key: emoji,
      },
      {for (final emoji in standardEmojis) emoji.emoji: emoji},
    );
  }

  /// Every section, unfiltered: Frequently Used (from [uses], most used
  /// first, only emojis this picker offers), the channels, then the standard
  /// categories.
  List<EmojiPickerSection> sections(List<EmojiUse> uses) {
    final frequent = <PickerEmoji>[];
    for (final use in uses) {
      final emoji = pickerEmojiForUse(
        use.id,
        customByKey: _customByKey,
        standardByEmoji: _standardByEmoji,
      );
      if (emoji == null) continue;
      frequent.add(emoji);
      if (frequent.length == maxFrequentShown) break;
    }
    return [
      if (frequent.isNotEmpty) FrequentEmojiSection(frequent),
      ..._channelSections,
      ..._standardSections,
    ];
  }
}

/// [sections] narrowed to emojis matching [filter]: channel emojis by name,
/// standard ones by short name or Unicode name. Frequently Used is hidden
/// while filtering, since its emojis also appear in their own section.
List<EmojiPickerSection> filterEmojiPickerSections(
  List<EmojiPickerSection> sections,
  String filter,
) {
  final query = filter.trim().toLowerCase().replaceAll(':', '');
  if (query.isEmpty) return sections;
  final spaced = query.replaceAll(_nameSeparators, ' ');
  bool matches(PickerEmoji emoji) => switch (emoji) {
    CustomPickerEmoji(:final emoji) => emoji.name.toLowerCase().contains(query),
    UnicodePickerEmoji(:final emoji) =>
      emoji.shortNames.any((name) => name.contains(query)) ||
          emoji.name.toLowerCase().contains(spaced),
  };
  return [
    for (final section in sections)
      if (section is! FrequentEmojiSection)
        if (section.emojis.where(matches).toList() case final emojis
            when emojis.isNotEmpty)
          section._withEmojis(emojis),
  ];
}
