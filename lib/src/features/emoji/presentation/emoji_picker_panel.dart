import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/emoji_providers.dart';
import '../domain/channel_emoji.dart';
import 'emoji_preview.dart';

/// Emoji picker for the search bars.
///
/// With [groupByChannel], emojis are split into per-channel sections with a
/// rail of channel avatars for jumping between them (like Discord). Otherwise
/// the first group's emojis are shown as a single grid (like YouTube live
/// chat).
class EmojiPickerPanel extends ConsumerStatefulWidget {
  final List<ChannelEmojiGroup> groups;
  final bool groupByChannel;
  final ValueChanged<ChannelEmoji> onSelected;

  const EmojiPickerPanel({
    super.key,
    required this.groups,
    required this.groupByChannel,
    required this.onSelected,
  });

  @override
  ConsumerState<EmojiPickerPanel> createState() => _EmojiPickerPanelState();
}

class _EmojiPickerPanelState extends ConsumerState<EmojiPickerPanel> {
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{};
  String _filter = '';
  ChannelEmoji? _hovered;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<ChannelEmojiGroup> get _visibleGroups {
    final filter = _filter.toLowerCase().replaceAll(':', '');
    return [
      for (final group in widget.groups)
        if (filter.isEmpty)
          group
        else if (group.emojis
                .where((e) => e.name.toLowerCase().contains(filter))
                .toList()
            case final matches when matches.isNotEmpty)
          group.copyWith(emojis: matches),
    ];
  }

  void _jumpTo(String channelId) {
    final context = _sectionKeys[channelId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = _visibleGroups;
    final showRail = widget.groupByChannel && widget.groups.length > 1;
    final width = (MediaQuery.sizeOf(context).width - 32).clamp(240.0, 380.0);

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
              onChanged: (v) => setState(() => _filter = v.trim()),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showRail) ...[
                  _ChannelRail(
                    groups: widget.groups,
                    onTap: (g) => _jumpTo(g.channelId),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: groups.isEmpty
                      ? Center(
                          child: Text(
                            widget.groups.isEmpty
                                ? 'No custom emojis found'
                                : 'No emoji match',
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final group in groups)
                                _EmojiSection(
                                  key: _sectionKeys.putIfAbsent(
                                    group.channelId,
                                    GlobalKey.new,
                                  ),
                                  group: group,
                                  onSelected: widget.onSelected,
                                  onHover: (e) => setState(() => _hovered = e),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _PreviewFooter(emoji: _hovered, groups: widget.groups),
        ],
      ),
    );
  }
}

class _ChannelAvatar extends StatelessWidget {
  final ChannelEmojiGroup group;
  final double radius;

  const _ChannelAvatar({required this.group, required this.radius});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = group.thumbnailUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: url != null
          ? ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              ),
            )
          : Text(
              group.displayTitle[0].toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: radius,
              ),
            ),
    );
  }
}

class _ChannelRail extends StatelessWidget {
  final List<ChannelEmojiGroup> groups;
  final ValueChanged<ChannelEmojiGroup> onTap;

  const _ChannelRail({required this.groups, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Tooltip(
                message: group.displayTitle,
                preferBelow: false,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onTap(group),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _ChannelAvatar(group: group, radius: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmojiSection extends StatelessWidget {
  final ChannelEmojiGroup group;
  final ValueChanged<ChannelEmoji> onSelected;
  final ValueChanged<ChannelEmoji?> onHover;

  const _EmojiSection({
    super.key,
    required this.group,
    required this.onSelected,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Row(
              children: [
                _ChannelAvatar(group: group, radius: 9),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.displayTitle.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            children: [
              for (final emoji in group.emojis)
                _EmojiButton(
                  emoji: emoji,
                  onTap: () => onSelected(emoji),
                  onHover: onHover,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final ChannelEmoji emoji;
  final VoidCallback onTap;
  final ValueChanged<ChannelEmoji?> onHover;

  const _EmojiButton({
    required this.emoji,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: emoji.token,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        onHover: (hovering) => onHover(hovering ? emoji : null),
        onFocusChange: (focused) => onHover(focused ? emoji : null),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: EmojiImage(url: emoji.url, size: 32),
        ),
      ),
    );
  }
}

class _PreviewFooter extends ConsumerWidget {
  final ChannelEmoji? emoji;
  final List<ChannelEmojiGroup> groups;

  const _PreviewFooter({required this.emoji, required this.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(emojiNamesProvider);
    final emoji = this.emoji;

    final Widget content;
    if (emoji != null) {
      final channel = groups
          .where((g) => g.channelId == emoji.channelId)
          .firstOrNull;
      content = Row(
        children: [
          EmojiImage(url: emoji.url, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emoji.resolved
                      ? emoji.token
                      : '${emoji.token}  (generated name)',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontStyle: emoji.resolved ? null : FontStyle.italic,
                    color: emoji.resolved
                        ? null
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (channel != null)
                  Text(
                    '${channel.displayTitle} · used ${emoji.usageCount}×',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      );
    } else if (status.isResolving) {
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
    } else if (status.lookupUnavailable) {
      content = Text(
        'Emoji name lookup is unavailable right now; some names are generated.',
        style: theme.textTheme.bodySmall,
      );
    } else {
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
