import 'package:dart_mappable/dart_mappable.dart';

import 'resolved_emoji.dart';

part 'emoji_names_state.mapper.dart';

/// Custom emoji names known on this device, and how looking up the rest is
/// going.
@MappableClass()
class EmojiNamesState with EmojiNamesStateMappable {
  /// Keyed by `emojiKey`.
  final Map<String, ResolvedEmoji> names;
  final bool isResolving;

  /// True when lookups are paused because YouTube's response format looked
  /// changed. Cached and fallback names keep working.
  final bool lookupUnavailable;

  const EmojiNamesState({
    this.names = const {},
    this.isResolving = false,
    this.lookupUnavailable = false,
  });
}
