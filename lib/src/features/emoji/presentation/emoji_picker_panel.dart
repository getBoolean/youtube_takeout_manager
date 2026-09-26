import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/channel_avatar.dart';
import '../application/emoji_providers.dart';
import '../domain/channel_emoji.dart';
import '../domain/emoji_use.dart';
import '../domain/picker_emoji.dart';
import '../domain/unicode_emoji.dart';
import 'emoji_preview.dart';

/// Emoji picker for the search bars, laid out like Discord's: Frequently
/// Used, one section per channel, then the standard emoji categories, with a
/// rail for jumping between sections.
class EmojiPickerPanel extends ConsumerStatefulWidget {
  final List<ChannelEmojiGroup> groups;

  /// Standard emojis to offer, in picker order.
  final List<UnicodeEmoji> standardEmojis;
  final ValueChanged<PickerEmoji> onSelected;

  const EmojiPickerPanel({
    super.key,
    required this.groups,
    required this.standardEmojis,
    required this.onSelected,
  });

  @override
  ConsumerState<EmojiPickerPanel> createState() => _EmojiPickerPanelState();
}

/// One picker section. [id] is [_frequentId], a channel id or a
/// [UnicodeEmojiCategory].
typedef _Section = ({
  Object id,
  String title,
  IconData? icon,
  ChannelEmojiGroup? channel,
  List<PickerEmoji> emojis,
});

const _frequentId = #frequent;
const _maxFrequent = 16;

IconData _categoryIcon(UnicodeEmojiCategory category) => switch (category) {
  UnicodeEmojiCategory.people => Icons.emoji_emotions_outlined,
  UnicodeEmojiCategory.nature => Icons.emoji_nature_outlined,
  UnicodeEmojiCategory.food => Icons.emoji_food_beverage_outlined,
  UnicodeEmojiCategory.activities => Icons.emoji_events_outlined,
  UnicodeEmojiCategory.travel => Icons.emoji_transportation_outlined,
  UnicodeEmojiCategory.objects => Icons.emoji_objects_outlined,
  UnicodeEmojiCategory.symbols => Icons.emoji_symbols_outlined,
  UnicodeEmojiCategory.flags => Icons.emoji_flags_outlined,
};

final _nameSeparators = RegExp('[_-]');

class _EmojiPickerPanelState extends ConsumerState<EmojiPickerPanel> {
  final _scrollController = ScrollController();
  final _sectionKeys = <Object, GlobalKey>{};
  final _hovered = ValueNotifier<PickerEmoji?>(null);
  String _filter = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _hovered.dispose();
    super.dispose();
  }

  List<UnicodeEmoji>? _standardSource;
  List<_Section> _standardSections = const [];
  Map<String, UnicodeEmoji> _standardByEmoji = const {};

  /// Builds the standard emoji sections when [EmojiPickerPanel.standardEmojis]
  /// changes.
  void _syncStandardSections() {
    final source = widget.standardEmojis;
    if (identical(source, _standardSource)) return;
    _standardSource = source;
    final byCategory = <UnicodeEmojiCategory, List<PickerEmoji>>{};
    for (final emoji in source) {
      byCategory
          .putIfAbsent(emoji.category, () => [])
          .add(UnicodePickerEmoji(emoji));
    }
    _standardSections = [
      for (final category in UnicodeEmojiCategory.values)
        if (byCategory[category] case final emojis?)
          (
            id: category,
            title: category.label,
            icon: _categoryIcon(category),
            channel: null,
            emojis: emojis,
          ),
    ];
    _standardByEmoji = {for (final emoji in source) emoji.emoji: emoji};
  }

  /// Every section, unfiltered.
  List<_Section> _allSections(List<EmojiUse> uses) {
    final channelSections = <_Section>[];
    final customById = <String, CustomPickerEmoji>{};
    for (final group in widget.groups) {
      if (group.emojis.isEmpty) continue;
      final emojis = [for (final e in group.emojis) CustomPickerEmoji(e)];
      for (final emoji in emojis) {
        customById[emoji.usageId] = emoji;
      }
      channelSections.add((
        id: group.channelId,
        title: group.displayTitle,
        icon: null,
        channel: group,
        emojis: emojis,
      ));
    }

    // Only emojis this picker offers, i.e. used in what the search covers.
    _syncStandardSections();
    final frequent = <PickerEmoji>[];
    for (final use in uses) {
      final PickerEmoji? emoji = use.id.startsWith('u:')
          ? switch (_standardByEmoji[use.id.substring(2)]) {
              final e? => UnicodePickerEmoji(e),
              null => null,
            }
          : customById[use.id];
      if (emoji == null) continue;
      frequent.add(emoji);
      if (frequent.length == _maxFrequent) break;
    }

    return [
      if (frequent.isNotEmpty)
        (
          id: _frequentId,
          title: 'Frequently Used',
          icon: Icons.schedule,
          channel: null,
          emojis: frequent,
        ),
      ...channelSections,
      ..._standardSections,
    ];
  }

  /// [all] narrowed to emojis matching the filter. Frequently Used is hidden
  /// while filtering, since its emojis also appear in their own section.
  List<_Section> _visibleSections(List<_Section> all) {
    final filter = _filter.toLowerCase().replaceAll(':', '');
    if (filter.isEmpty) return all;
    final spaced = filter.replaceAll(_nameSeparators, ' ');
    bool matches(PickerEmoji emoji) => switch (emoji) {
      CustomPickerEmoji(:final emoji) => emoji.name.toLowerCase().contains(
        filter,
      ),
      UnicodePickerEmoji(:final emoji) =>
        emoji.shortNames.any((name) => name.contains(filter)) ||
            emoji.name.toLowerCase().contains(spaced),
    };
    return [
      for (final section in all)
        if (section.id != _frequentId)
          if (section.emojis.where(matches).toList() case final emojis
              when emojis.isNotEmpty)
            (
              id: section.id,
              title: section.title,
              icon: section.icon,
              channel: section.channel,
              emojis: emojis,
            ),
    ];
  }

  void _jumpTo(Object id) {
    final context = _sectionKeys[id]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _setFilter(String value) {
    setState(() => _filter = value.trim());
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uses = ref.watch(frequentEmojisProvider).value ?? const [];
    final all = _allSections(uses);
    final sections = _visibleSections(all);
    final width = (MediaQuery.sizeOf(context).width - 32).clamp(240.0, 380.0);

    // The size must stay tight: MenuAnchor measures its children's intrinsic
    // width, which a scroll view can't report.
    return SizedBox(
      width: width,
      height: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Find emoji',
                border: OutlineInputBorder(),
              ),
              onChanged: _setFilter,
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionRail(sections: all, onTap: (s) => _jumpTo(s.id)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: sections.isEmpty
                      ? Center(
                          child: Text(
                            'No emoji match',
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            for (final section in sections) ...[
                              SliverToBoxAdapter(
                                child: _SectionHeader(
                                  key: _sectionKeys.putIfAbsent(
                                    section.id,
                                    GlobalKey.new,
                                  ),
                                  section: section,
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                sliver: SliverGrid.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 40,
                                      ),
                                  itemCount: section.emojis.length,
                                  itemBuilder: (context, i) {
                                    final emoji = section.emojis[i];
                                    return _EmojiCell(
                                      emoji: emoji,
                                      hovered: _hovered,
                                      onTap: () => widget.onSelected(emoji),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ValueListenableBuilder(
            valueListenable: _hovered,
            builder: (context, emoji, _) =>
                _PreviewFooter(emoji: emoji, groups: widget.groups),
          ),
        ],
      ),
    );
  }
}

/// A section's channel avatar or category icon.
class _SectionIcon extends StatelessWidget {
  final _Section section;
  final double size;

  const _SectionIcon({required this.section, required this.size});

  @override
  Widget build(BuildContext context) {
    if (section.channel case final channel?) {
      return ChannelAvatar(
        name: channel.displayTitle,
        thumbnailUrl: channel.thumbnailUrl,
        radius: size / 2,
      );
    }
    return SizedBox.square(
      dimension: size,
      child: Icon(
        section.icon,
        size: size * 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SectionRail extends StatelessWidget {
  final List<_Section> sections;
  final ValueChanged<_Section> onTap;

  const _SectionRail({required this.sections, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: ListView(
        // The menu's own scroll view uses the primary controller.
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final (i, section) in sections.indexed) ...[
            // Separates Frequently Used and channels from the categories.
            if (i > 0 &&
                section.id is UnicodeEmojiCategory &&
                sections[i - 1].id is! UnicodeEmojiCategory)
              const Divider(height: 9, indent: 12, endIndent: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Tooltip(
                message: section.title,
                preferBelow: false,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onTap(section),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _SectionIcon(section: section, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final _Section section;

  const _SectionHeader({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          _SectionIcon(section: section, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiCell extends StatelessWidget {
  final PickerEmoji emoji;
  final ValueNotifier<PickerEmoji?> hovered;
  final VoidCallback onTap;

  const _EmojiCell({
    required this.emoji,
    required this.hovered,
    required this.onTap,
  });

  void _setHovered(bool value) {
    if (value) {
      hovered.value = emoji;
    } else if (hovered.value == emoji) {
      hovered.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cell = Semantics(
      label: emoji.token,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        onHover: _setHovered,
        onFocusChange: _setHovered,
        child: Center(
          child: ExcludeSemantics(
            child: PickerEmojiImage(emoji: emoji, size: 32),
          ),
        ),
      ),
    );
    return switch (emoji) {
      CustomPickerEmoji(:final emoji) => EmojiUrlMenu(
        url: emoji.url,
        longPress: true,
        child: cell,
      ),
      UnicodePickerEmoji() => cell,
    };
  }
}

class _PreviewFooter extends ConsumerWidget {
  final PickerEmoji? emoji;
  final List<ChannelEmojiGroup> groups;

  const _PreviewFooter({required this.emoji, required this.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(emojiNamesProvider);
    final hasChannelEmojis = groups.any((g) => g.emojis.isNotEmpty);

    Widget details(PickerEmoji emoji, String? subtitle, {bool? resolved}) {
      final generated = resolved == false;
      return Row(
        children: [
          PickerEmojiImage(emoji: emoji, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  generated ? '${emoji.token}  (generated name)' : emoji.token,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontStyle: generated ? FontStyle.italic : null,
                    color: generated
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      );
    }

    final Widget content;
    switch (emoji) {
      case final CustomPickerEmoji picked:
        final channel = groups
            .where((g) => g.channelId == picked.emoji.channelId)
            .firstOrNull;
        content = details(
          picked,
          channel == null
              ? null
              : '${channel.displayTitle} · used ${picked.emoji.usageCount}×',
          resolved: picked.emoji.resolved,
        );
      case final UnicodePickerEmoji picked:
        final name = picked.emoji.name;
        content = details(
          picked,
          '${name[0].toUpperCase()}${name.substring(1)} · '
          '${picked.emoji.category.label}',
        );
      case null when hasChannelEmojis && status.isResolving:
        content = Row(
          children: [
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('Looking up emoji names…', style: theme.textTheme.bodySmall),
          ],
        );
      case null when hasChannelEmojis && status.lookupUnavailable:
        content = Text(
          'Emoji name lookup is unavailable right now; some names are generated.',
          style: theme.textTheme.bodySmall,
        );
      case null:
        content = Text(
          'Pick an emoji to search for it',
          style: theme.textTheme.bodySmall,
        );
    }

    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(alignment: Alignment.centerLeft, child: content),
      ),
    );
  }
}
