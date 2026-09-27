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
  late Future<void> _cacheLoaded;

  @override
  EmojiNamesState build() {
    ref.watch(emojiNameCacheRepositoryProvider);
    _cacheLoaded = _loadCache();
    return const EmojiNamesState();
  }

  /// Completes once the names kept on this device are in.
  Future<void> get cacheLoaded => _cacheLoaded;

  Future<void> _loadCache() async {
    final cached = await _cacheRepository.loadNames();
    if (cached.isNotEmpty) {
      state = state.copyWith(names: {...cached, ...state.names});
    }
  }

  /// Notes that names are being looked up, and whether lookups are paused.
  void setResolving({required bool resolving, bool? lookupUnavailable}) =>
      state = state.copyWith(
        isResolving: resolving,
        lookupUnavailable: lookupUnavailable,
      );

  /// Notes that lookups are paused, YouTube's responses having changed.
  void pauseLookups() => state = state.copyWith(lookupUnavailable: true);

  /// Adds looked-up names and keeps them on this device.
  Future<void> addNames(Map<String, ResolvedEmoji> found) async {
    state = state.copyWith(names: {...state.names, ...found});
    await _cacheRepository.saveNames(state.names);
  }
}

/// Resolved emoji names keyed by `emojiKey`, for search matching.
@Riverpod(keepAlive: true)
Map<String, String> emojiNamesByKey(Ref ref) {
  final names = ref.watch(emojiNamesProvider).names;
  return names.map((key, value) => MapEntry(key, value.name));
}
