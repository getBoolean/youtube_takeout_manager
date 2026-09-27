// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequent_emoji_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(frequentEmojiRepository)
final frequentEmojiRepositoryProvider = FrequentEmojiRepositoryProvider._();

final class FrequentEmojiRepositoryProvider
    extends
        $FunctionalProvider<
          FrequentEmojiRepository,
          FrequentEmojiRepository,
          FrequentEmojiRepository
        >
    with $Provider<FrequentEmojiRepository> {
  FrequentEmojiRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'frequentEmojiRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$frequentEmojiRepositoryHash();

  @$internal
  @override
  $ProviderElement<FrequentEmojiRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FrequentEmojiRepository create(Ref ref) {
    return frequentEmojiRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FrequentEmojiRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FrequentEmojiRepository>(value),
    );
  }
}

String _$frequentEmojiRepositoryHash() =>
    r'bbcbd55da4df9260f69661cdb45fe796e3d4cca1';
