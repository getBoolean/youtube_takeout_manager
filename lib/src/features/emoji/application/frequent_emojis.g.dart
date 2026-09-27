// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequent_emojis.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.

@ProviderFor(FrequentEmojis)
final frequentEmojisProvider = FrequentEmojisProvider._();

/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.
final class FrequentEmojisProvider
    extends $AsyncNotifierProvider<FrequentEmojis, List<EmojiUse>> {
  /// Emojis the user inserted into a search, most used first (ties: most
  /// recent). Once full, the least recently used entry makes room for a new one.
  FrequentEmojisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'frequentEmojisProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$frequentEmojisHash();

  @$internal
  @override
  FrequentEmojis create() => FrequentEmojis();
}

String _$frequentEmojisHash() => r'f453a2123fcdd10d4710da5660bf5906132652ac';

/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.

abstract class _$FrequentEmojis extends $AsyncNotifier<List<EmojiUse>> {
  FutureOr<List<EmojiUse>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<EmojiUse>>, List<EmojiUse>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<EmojiUse>>, List<EmojiUse>>,
              AsyncValue<List<EmojiUse>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
