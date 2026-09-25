import 'package:flutter/material.dart';

import '../domain/channel_emoji.dart';
import '../domain/unicode_emoji.dart';
import 'emoji_preview.dart';

/// A [TextEditingController] that renders known `:name:` tokens as their
/// channel emoji image while keeping the raw `:name:` text as the value.
///
/// Each token is drawn as a [WidgetSpan] (one placeholder character) followed
/// by the rest of the token as invisible zero-size text, so span offsets stay
/// equal to text offsets. The caret can't rest inside a token, and deleting a
/// token's edge character removes the whole token.
///
/// Typing the closing colon of a standard emoji's `:name:` replaces it with
/// the emoji (like Discord), unless a channel emoji has that name.
class EmojiTextEditingController extends TextEditingController {
  EmojiTextEditingController({super.text});

  static final _token = RegExp(r':_?([\w-]+):');
  static final _wordChar = RegExp(r'\w');
  static final _plainName = RegExp(r'^[\w-]+$');

  /// Standard emojis a typed `:name:` converts to, keyed by lowercase short
  /// name.
  Map<String, UnicodeEmoji> unicodeEmojisByName = const {};

  /// Called after a typed `:name:` was converted to [UnicodeEmoji.emoji].
  ValueChanged<UnicodeEmoji>? onShortcodeConverted;

  Map<String, ChannelEmoji> _emojisByName = const {};

  /// Emojis to render, keyed by lowercase name.
  Map<String, ChannelEmoji> get emojisByName => _emojisByName;
  set emojisByName(Map<String, ChannelEmoji> value) {
    if (identical(value, _emojisByName)) return;
    _emojisByName = value;
    notifyListeners();
  }

  double emojiSize = 20;

  ChannelEmoji? _lookup(String name) => _emojisByName[name.toLowerCase()];

  /// Ranges of known emoji tokens in [text], in order.
  List<(TextRange, ChannelEmoji)> emojiTokens(String text) {
    if (_emojisByName.isEmpty || !text.contains(':')) return const [];
    final result = <(TextRange, ChannelEmoji)>[];
    for (final match in _token.allMatches(text)) {
      final emoji = _lookup(match[1]!);
      if (emoji != null) {
        result.add((TextRange(start: match.start, end: match.end), emoji));
      }
    }
    return result;
  }

  @override
  set value(TextEditingValue newValue) {
    super.value = _keepTokensAtomic(value, newValue);
  }

  TextEditingValue _keepTokensAtomic(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    if (next.composing.isValid && !next.composing.isCollapsed) return next;

    // Single-character delete at a token edge removes the whole token.
    final oldSel = old.selection;
    final nextSel = next.selection;
    if (oldSel.isValid &&
        oldSel.isCollapsed &&
        nextSel.isValid &&
        nextSel.isCollapsed &&
        next.text.length == old.text.length - 1) {
      final caret = oldSel.baseOffset;
      final isBackspace =
          nextSel.baseOffset == caret - 1 &&
          next.text == old.text.replaceRange(caret - 1, caret, '');
      final isDelete =
          nextSel.baseOffset == caret &&
          caret < old.text.length &&
          next.text == old.text.replaceRange(caret, caret + 1, '');
      for (final (range, _) in emojiTokens(old.text)) {
        if ((isBackspace && range.end == caret) ||
            (isDelete && range.start == caret)) {
          return TextEditingValue(
            text: old.text.replaceRange(range.start, range.end, ''),
            selection: TextSelection.collapsed(offset: range.start),
          );
        }
      }
    }

    final converted = _convertShortcode(old, next);
    if (converted != null) return converted;

    // Keep the caret / selection edges out of token interiors.
    if (!nextSel.isValid) return next;
    final tokens = emojiTokens(next.text);
    if (tokens.isEmpty) return next;

    int snap(int offset, int? previous) {
      for (final (range, _) in tokens) {
        if (offset <= range.start || offset >= range.end) continue;
        if (previous != null && previous <= range.start) return range.end;
        if (previous != null && previous >= range.end) return range.start;
        return offset - range.start < range.end - offset
            ? range.start
            : range.end;
      }
      return offset;
    }

    final prevBase = oldSel.isValid ? oldSel.baseOffset : null;
    final prevExtent = oldSel.isValid ? oldSel.extentOffset : null;
    final base = snap(nextSel.baseOffset, prevBase);
    final extent = snap(nextSel.extentOffset, prevExtent);
    if (base == nextSel.baseOffset && extent == nextSel.extentOffset) {
      return next;
    }
    return next.copyWith(
      selection: nextSel.copyWith(baseOffset: base, extentOffset: extent),
    );
  }

  /// When [next] types a single `:` that closes `:name:` for a standard
  /// emoji, the value with that token replaced by the emoji.
  TextEditingValue? _convertShortcode(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final oldSel = old.selection;
    final nextSel = next.selection;
    if (unicodeEmojisByName.isEmpty ||
        !oldSel.isValid ||
        !oldSel.isCollapsed ||
        !nextSel.isValid ||
        !nextSel.isCollapsed) {
      return null;
    }
    final caret = nextSel.baseOffset;
    if (caret != oldSel.baseOffset + 1 ||
        next.text.length != old.text.length + 1 ||
        next.text[caret - 1] != ':' ||
        next.text != old.text.replaceRange(caret - 1, caret - 1, ':')) {
      return null;
    }

    final open = caret >= 2 ? next.text.lastIndexOf(':', caret - 2) : -1;
    if (open < 0) return null;
    // `10:30:` or `word:fire:` isn't a shortcode.
    if (open > 0 && _wordChar.hasMatch(next.text[open - 1])) return null;
    final name = next.text.substring(open + 1, caret - 1).toLowerCase();
    // A channel emoji with this name wins; `:_name:` never matches.
    if (!_plainName.hasMatch(name) || _emojisByName.containsKey(name)) {
      return null;
    }
    final emoji = unicodeEmojisByName[name];
    if (emoji == null) return null;

    onShortcodeConverted?.call(emoji);
    return TextEditingValue(
      text: next.text.replaceRange(open, caret, emoji.emoji),
      selection: TextSelection.collapsed(offset: open + emoji.emoji.length),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final tokens = emojiTokens(text);
    final composing = value.composing;
    if (tokens.isEmpty ||
        (withComposing && composing.isValid && !composing.isCollapsed)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final hidden = (style ?? const TextStyle()).copyWith(
      color: Colors.transparent,
      fontSize: 0.01,
      letterSpacing: 0,
    );
    final children = <InlineSpan>[];
    var cursor = 0;
    for (final (range, emoji) in tokens) {
      if (range.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      children
        ..add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            // A click places the caret instead of opening the preview.
            child: EmojiPreview(
              url: emoji.url,
              size: emojiSize,
              name: emoji.name,
              resolved: emoji.resolved,
              tapToPreview: false,
            ),
          ),
        )
        ..add(
          TextSpan(
            text: text.substring(range.start + 1, range.end),
            style: hidden,
          ),
        );
      cursor = range.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: style, children: children);
  }
}
