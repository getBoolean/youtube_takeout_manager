import 'dart:async';

import 'package:cue/cue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';
import '../application/emoji_providers.dart';
import '../domain/channel_emoji.dart';
import '../domain/picker_emoji.dart';
import '../domain/unicode_emoji.dart';
import 'emoji_picker_panel.dart';
import 'emoji_preview.dart';
import 'emoji_text_editing_controller.dart';

/// Emojis offered by a [DebouncedSearchBar]: the ones used in the content it
/// searches.
class EmojiSearchConfig {
  final List<ChannelEmojiGroup> groups;

  /// Standard emojis, in picker order.
  final List<UnicodeEmoji> standardEmojis;

  const EmojiSearchConfig({required this.groups, required this.standardEmojis});

  bool get isEmpty =>
      standardEmojis.isEmpty && groups.every((g) => g.emojis.isEmpty);

  @override
  bool operator ==(Object other) =>
      other is EmojiSearchConfig &&
      identical(other.groups, groups) &&
      identical(other.standardEmojis, standardEmojis);

  @override
  int get hashCode =>
      Object.hash(identityHashCode(groups), identityHashCode(standardEmojis));
}

/// A [SearchBar] wrapper that debounces [onQueryChanged] and exposes a clear
/// button when the field is non-empty.
///
/// When [emojis] is provided, it also offers an emoji picker button, `:name`
/// autocomplete for channel and standard emojis, renders complete channel
/// `:name:` tokens as the emoji image, and converts typed standard `:name:`s
/// to the emoji.
class DebouncedSearchBar extends ConsumerStatefulWidget {
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
  ConsumerState<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

/// Matches an unfinished `:name` directly before the caret.
final _emojiFragment = RegExp(r':_?([\w-]{2,})$');
final _wordChar = RegExp(r'\w');
const _maxSuggestions = 8;

class _DebouncedSearchBarState extends ConsumerState<DebouncedSearchBar> {
  final EmojiTextEditingController _controller = EmojiTextEditingController();
  late final FocusNode _focusNode = FocusNode(onKeyEvent: _handleKey);
  final OverlayPortalController _suggestionsPortal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  Timer? _debounce;
  bool _hasText = false;

  List<CustomPickerEmoji> _customEmojis = const [];
  List<UnicodeEmoji> _standardEmojis = const [];
  Map<String, UnicodeEmoji> _standardByName = const {};
  List<PickerEmoji> _suggestions = const [];
  int _highlighted = 0;
  TextRange? _fragment;

  @override
  void initState() {
    super.initState();
    _controller.onShortcodeConverted = (emoji) =>
        _recordUse(UnicodePickerEmoji(emoji));
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
    _customEmojis = [
      for (final g in groups)
        for (final emoji in g.emojis) CustomPickerEmoji(emoji),
    ];
    final byName = <String, ChannelEmoji>{};
    for (final CustomPickerEmoji(:emoji) in _customEmojis) {
      byName.putIfAbsent(emoji.name.toLowerCase(), () => emoji);
    }
    _standardEmojis = widget.emojis?.standardEmojis ?? const [];
    _standardByName = {
      for (final emoji in _standardEmojis)
        for (final name in emoji.shortNames) name: emoji,
    };
    _syncingEmojis = true;
    _controller
      ..unicodeEmojisByName = _standardByName
      ..emojisByName = byName;
    _syncingEmojis = false;
  }

  void _recordUse(PickerEmoji emoji) {
    unawaited(
      ref.read(frequentEmojisProvider.notifier).recordUse(emoji.usageId),
    );
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

  void _insertEmoji(PickerEmoji emoji, {TextRange? replacing}) {
    final value = _controller.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final start = replacing?.start ?? selection.start;
    final end = replacing?.end ?? selection.end;
    final insert = emoji.insertText;
    final newText = text.replaceRange(start, end, insert);
    final caret = TextSelection.collapsed(offset: start + insert.length);
    _controller.value = TextEditingValue(text: newText, selection: caret);
    _handleChanged(newText);
    _recordUse(emoji);
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
    List<PickerEmoji> next = const [];
    TextRange? fragment;
    final value = _controller.value;
    if (_focusNode.hasFocus &&
        widget.emojis != null &&
        value.selection.isValid &&
        value.selection.isCollapsed) {
      final before = value.text.substring(0, value.selection.baseOffset);
      final match = _emojiFragment.firstMatch(before);
      // `10:30` or `word:sh` isn't the start of an emoji name.
      if (match != null &&
          !(match.start > 0 && _wordChar.hasMatch(before[match.start - 1]))) {
        fragment = TextRange(start: match.start, end: match.end);
        next = _rankSuggestions(
          match[1]!.toLowerCase(),
          // `:_name` is YouTube's syntax for channel emojis.
          includeStandard: !match[0]!.startsWith(':_'),
        );
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

  /// Exact matches, then prefix matches, then other matches; channel emojis
  /// (most used first) before standard ones within each, so an emoji and a
  /// standard one with the same name are both offered.
  List<PickerEmoji> _rankSuggestions(
    String fragment, {
    required bool includeStandard,
  }) {
    final customExact = <CustomPickerEmoji>[];
    final customPrefix = <CustomPickerEmoji>[];
    final customContains = <CustomPickerEmoji>[];
    for (final emoji in _customEmojis) {
      final name = emoji.name.toLowerCase();
      if (name == fragment) {
        customExact.add(emoji);
      } else if (name.startsWith(fragment)) {
        customPrefix.add(emoji);
      } else if (name.contains(fragment)) {
        customContains.add(emoji);
      }
    }
    int byUsage(CustomPickerEmoji a, CustomPickerEmoji b) =>
        b.emoji.usageCount.compareTo(a.emoji.usageCount);
    customPrefix.sort(byUsage);
    customContains.sort(byUsage);

    final standardExact = <UnicodePickerEmoji>[];
    final standardPrefix = <(int, UnicodePickerEmoji)>[];
    final standardContains = <UnicodePickerEmoji>[];
    if (includeStandard) {
      for (final (i, emoji) in _standardEmojis.indexed) {
        String? prefix;
        String? contains;
        for (final name in emoji.shortNames) {
          if (name == fragment) {
            standardExact.add(UnicodePickerEmoji(emoji, name));
            prefix = contains = null;
            break;
          }
          if (name.startsWith(fragment)) {
            prefix ??= name;
          } else if (name.contains(fragment)) {
            contains ??= name;
          }
        }
        if (prefix != null) {
          standardPrefix.add((i, UnicodePickerEmoji(emoji, prefix)));
        } else if (contains != null) {
          standardContains.add(UnicodePickerEmoji(emoji, contains));
        }
      }
      // Shortest names first (`:heart` → ❤️ before 😍 heart_eyes).
      standardPrefix.sort((a, b) {
        final byLength = a.$2.name.length.compareTo(b.$2.name.length);
        return byLength != 0 ? byLength : a.$1.compareTo(b.$1);
      });
    }

    return [
      ...customExact,
      ...standardExact,
      ...customPrefix,
      for (final (_, emoji) in standardPrefix) emoji,
      ...customContains,
      ...standardContains,
    ].take(_maxSuggestions).toList();
  }

  void _acceptSuggestion(PickerEmoji emoji) {
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
                    channelTitle: switch (emoji) {
                      CustomPickerEmoji(:final emoji) =>
                        widget.emojis?.groups
                            .where((g) => g.channelId == emoji.channelId)
                            .firstOrNull
                            ?.displayTitle,
                      UnicodePickerEmoji() => null,
                    },
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
            standardEmojis: config.standardEmojis,
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
  final PickerEmoji emoji;
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
    final generatedName = switch (emoji) {
      CustomPickerEmoji(:final emoji) => !emoji.resolved,
      UnicodePickerEmoji() => false,
    };
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
              PickerEmojiImage(emoji: emoji, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  emoji.token,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: generatedName ? FontStyle.italic : null,
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
