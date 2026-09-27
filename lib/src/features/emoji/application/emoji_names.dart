import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/emoji_name_cache_repository.dart';
import '../domain/emoji_names_state.dart';
import '../domain/resolved_emoji.dart';

part 'emoji_names.g.dart';

/// Custom emoji names resolved from YouTube live chat replays, keyed by
/// `emojiKey`, kept on this device. Looking up the rest is
/// `EmojiNameResolver`'s.
@Riverpod(keepAlive: true)
class EmojiNames extends _$EmojiNames {
  EmojiNameCacheRepository get _cacheRepository =>
      ref.read(emojiNameCacheRepositoryProvider);

  @override
  Future<EmojiNamesState> build() async => EmojiNamesState(
    names: await ref.watch(emojiNameCacheRepositoryProvider).loadNames(),
  );

  EmojiNamesState get _current => state.value ?? const EmojiNamesState();

  /// Notes that names are being looked up, and whether lookups are paused.
  void setResolving({required bool resolving, bool? lookupUnavailable}) =>
      state = AsyncData(
        _current.copyWith(
          isResolving: resolving,
          lookupUnavailable: lookupUnavailable,
        ),
      );

  /// Notes that lookups are paused, YouTube's responses having changed.
  void pauseLookups() =>
      state = AsyncData(_current.copyWith(lookupUnavailable: true));

  /// Adds looked-up names and keeps them on this device.
  Future<void> addNames(Map<String, ResolvedEmoji> found) async {
    state = AsyncData(_current.copyWith(names: {..._current.names, ...found}));
    await _cacheRepository.saveNames(_current.names);
  }
}

/// Resolved emoji names keyed by `emojiKey`, for search matching.
@Riverpod(keepAlive: true)
Map<String, String> emojiNamesByKey(Ref ref) {
  final names = ref.watch(emojiNamesProvider).value?.names ?? const {};
  return names.map((key, value) => MapEntry(key, value.name));
}
