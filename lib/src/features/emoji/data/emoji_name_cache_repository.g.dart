// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_name_cache_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(emojiNameCacheRepository)
final emojiNameCacheRepositoryProvider = EmojiNameCacheRepositoryProvider._();

final class EmojiNameCacheRepositoryProvider
    extends
        $FunctionalProvider<
          EmojiNameCacheRepository,
          EmojiNameCacheRepository,
          EmojiNameCacheRepository
        >
    with $Provider<EmojiNameCacheRepository> {
  EmojiNameCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emojiNameCacheRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emojiNameCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<EmojiNameCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmojiNameCacheRepository create(Ref ref) {
    return emojiNameCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmojiNameCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmojiNameCacheRepository>(value),
    );
  }
}

String _$emojiNameCacheRepositoryHash() =>
    r'7e7c71f3a457e014b197a8fde66f1f6829467c8f';
