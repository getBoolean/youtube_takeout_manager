import 'dart:async';

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/channel_emoji.dart';
import 'cue_motion.dart';
import 'emoji_picker_panel.dart';
import 'emoji_preview.dart';
import 'emoji_text_editing_controller.dart';

/// Custom emojis offered by a [DebouncedSearchBar].
class EmojiSearchConfig {
  final List<ChannelEmojiGroup> groups;

  /// Show one picker section per channel (channels page) instead of a single
  /// grid (channel page).
  final bool groupByChannel;

  const EmojiSearchConfig({required this.groups, this.groupByChannel = false});

  bool get isEmpty => groups.every((g) => g.emojis.isEmpty);

  @override
  bool operator ==(Object other) =>
      other is EmojiSearchConfig &&
      identical(other.groups, groups) &&
      other.groupByChannel == groupByChannel;

  @override
  int get hashCode => Object.hash(identityHashCode(groups), groupByChannel);
}

/// A [SearchBar] wrapper that debounces [onQueryChanged] and exposes a clear
/// button when the field is non-empty.
///
/// When [emojis] is provided, it also offers an emoji picker button, `:name`
/// autocomplete, and renders complete `:name:` tokens as the emoji image.
class DebouncedSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onQueryChanged;
  final Duration debounce;
  final bool enabled;
  final List<Widget>? trailing;
  final EmojiSearchConfig? emojis;

  const DebouncedSearchBar({
    super.key,
    required this.hintText,
    required this.onQueryChanged,
    this.debounce = const Duration(milliseconds: 300),
    this.enabled = true,
    this.trailing,
    this.emojis,
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

/// Matches an unfinished `:name` directly before the caret.
final _emojiFragment = RegExp(r':_?([\w-]{2,})$');
const _maxSuggestions = 8;

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  final EmojiTextEditingController _controller = EmojiTextEditingController();
  late final FocusNode _focusNode = FocusNode(onKeyEvent: _handleKey);
  final OverlayPortalController _suggestionsPortal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  Timer? _debounce;
  bool _hasText = false;

  List<ChannelEmoji> _allEmojis = const [];
  List<ChannelEmoji> _suggestions = const [];
  int _highlighted = 0;
  TextRange? _fragment;

  @override
  void initState() {
    super.initState();
    _syncEmojis();
    _controller.addListener(_updateSuggestions);
    _focusNode.addListener(_updateSuggestions);
  }

  @override
  void didUpdateWidget(DebouncedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emojis != widget.emojis) _syncEmojis();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _syncingEmojis = false;

  /// Called from initState/didUpdateWidget, so the controller notification
  /// it triggers must not update suggestions (setState during build).
  void _syncEmojis() {
    final groups = widget.emojis?.groups ?? const <ChannelEmojiGroup>[];
    _allEmojis = [for (final g in groups) ...g.emojis];
    final byName = <String, ChannelEmoji>{};
    for (final emoji in _allEmojis) {
      byName.putIfAbsent(emoji.name.toLowerCase(), () => emoji);
    }
    _syncingEmojis = true;
    _controller.emojisByName = byName;
    _syncingEmojis = false;
  }

  void _handleChanged(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () {
      widget.onQueryChanged(value);
    });
  }

  void _handleClear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _hasText = false);
    widget.onQueryChanged('');
  }

  // --- Emoji insertion & autocomplete ---

  void _insertEmoji(ChannelEmoji emoji, {TextRange? replacing}) {
    final value = _controller.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final start = replacing?.start ?? selection.start;
    final end = replacing?.end ?? selection.end;
    final newText = text.replaceRange(start, end, emoji.token);
    final caret = TextSelection.collapsed(offset: start + emoji.token.length);
    _controller.value = TextEditingValue(text: newText, selection: caret);
    _handleChanged(newText);
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      // Desktop/web text fields select all when they gain focus, which would
      // make the next insert replace everything. Restore the caret once the
      // focus change has been applied.
      scheduleMicrotask(() {
        if (mounted && _controller.text == newText) {
          _controller.selection = caret;
        }
      });
    }
  }

  void _updateSuggestions() {
    if (_syncingEmojis) return;
    List<ChannelEmoji> next = const [];
    TextRange? fragment;
    final value = _controller.value;
    if (_focusNode.hasFocus &&
        _allEmojis.isNotEmpty &&
        value.selection.isValid &&
        value.selection.isCollapsed) {
      final before = value.text.substring(0, value.selection.baseOffset);
      final match = _emojiFragment.firstMatch(before);
      if (match != null) {
        fragment = TextRange(start: match.start, end: match.end);
        next = _rankSuggestions(match[1]!.toLowerCase());
      }
    }

    final changed =
        next.length != _suggestions.length ||
        !Iterable.generate(
          next.length,
        ).every((i) => next[i] == _suggestions[i]);
    _fragment = fragment;
    if (changed) {
      setState(() {
        _suggestions = next;
        _highlighted = 0;
      });
    }
    if (next.isEmpty) {
      _suggestionsPortal.hide();
    } else {
      _suggestionsPortal.show();
    }
  }

  List<ChannelEmoji> _rankSuggestions(String fragment) {
    final prefix = <ChannelEmoji>[];
    final contains = <ChannelEmoji>[];
    for (final emoji in _allEmojis) {
      final name = emoji.name.toLowerCase();
      if (name.startsWith(fragment)) {
        prefix.add(emoji);
      } else if (name.contains(fragment)) {
        contains.add(emoji);
      }
    }
    int byUsage(ChannelEmoji a, ChannelEmoji b) =>
        b.usageCount.compareTo(a.usageCount);
    prefix.sort(byUsage);
    contains.sort(byUsage);
    return [...prefix, ...contains].take(_maxSuggestions).toList();
  }

  void _acceptSuggestion(ChannelEmoji emoji) {
    _insertEmoji(emoji, replacing: _fragment);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (_suggestions.isEmpty || !_suggestionsPortal.isShowing) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() => _highlighted = (_highlighted + 1) % _suggestions.length);
      case LogicalKeyboardKey.arrowUp:
        setState(
          () => _highlighted =
              (_highlighted - 1 + _suggestions.length) % _suggestions.length,
        );
      case LogicalKeyboardKey.enter ||
          LogicalKeyboardKey.numpadEnter ||
          LogicalKeyboardKey.tab:
        _acceptSuggestion(_suggestions[_highlighted]);
      case LogicalKeyboardKey.escape:
        _suggestionsPortal.hide();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    final fragment = _fragment;
    final typed = fragment == null
        ? ''
        : _controller.text.substring(fragment.start, fragment.end);
    return Positioned(
      width: _link.leaderSize?.width,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        offset: const Offset(0, 4),
        // Taps here must not count as "outside" the field and unfocus it.
        child: TextFieldTapRegion(
          child: Material(
            elevation: 3,
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Text(
                    'EMOJI MATCHING $typed'.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final (i, emoji) in _suggestions.indexed)
                  _SuggestionTile(
                    emoji: emoji,
                    channelTitle: widget.emojis?.groups
                        .where((g) => g.channelId == emoji.channelId)
                        .firstOrNull
                        ?.displayTitle,
                    highlighted: i == _highlighted,
                    onHover: () => setState(() => _highlighted = i),
                    onTap: () => _acceptSuggestion(emoji),
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiButton() {
    final config = widget.emojis!;
    return MenuAnchor(
      builder: (context, controller, _) => IconButton(
        icon: const Icon(Icons.add_reaction_outlined),
        tooltip: 'Search by emoji',
        onPressed: widget.enabled
            ? () => controller.isOpen ? controller.close() : controller.open()
            : null,
      ),
      menuChildren: [
        Builder(
          builder: (context) => EmojiPickerPanel(
            groups: config.groups,
            groupByChannel: config.groupByChannel,
            onSelected: (emoji) {
              MenuController.maybeOf(context)?.close();
              _insertEmoji(emoji);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = premiumSpring(context);
    final showEmojis = widget.emojis != null && !widget.emojis!.isEmpty;
    return OverlayPortal(
      controller: _suggestionsPortal,
      overlayChildBuilder: _buildSuggestions,
      child: CompositedTransformTarget(
        link: _link,
        child: SearchBar(
          controller: _controller,
          focusNode: _focusNode,
          hintText: widget.hintText,
          enabled: widget.enabled,
          leading: const Icon(Icons.search),
          trailing: [
            Cue.onToggle(
              toggled: _hasText,
              motion: motion,
              reverseMotion: motion,
              acts: const [
                ClipAct.width(),
                OpacityAct.fadeIn(),
                ScaleAct(from: 0.7),
              ],
              child: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear',
                onPressed: _handleClear,
              ),
            ),
            if (showEmojis) _buildEmojiButton(),
            ...?widget.trailing,
          ],
          onChanged: _handleChanged,
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final ChannelEmoji emoji;
  final String? channelTitle;
  final bool highlighted;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.emoji,
    required this.channelTitle,
    required this.highlighted,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        child: Container(
          color: highlighted ? theme.colorScheme.secondaryContainer : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              EmojiImage(url: emoji.url, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  emoji.token,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: emoji.resolved ? null : FontStyle.italic,
                  ),
                ),
              ),
              if (channelTitle != null)
                Flexible(
                  child: Text(
                    channelTitle!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
