// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji_name_resolver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Looks up names for the custom emojis in the viewed channel's live chats
/// once they're loaded. An effect: nothing depends on it, so it can read
/// any provider.

@ProviderFor(EmojiNameResolver)
final emojiNameResolverProvider = EmojiNameResolverProvider._();

/// Looks up names for the custom emojis in the viewed channel's live chats
/// once they're loaded. An effect: nothing depends on it, so it can read
/// any provider.
final class EmojiNameResolverProvider
    extends $NotifierProvider<EmojiNameResolver, void> {
  /// Looks up names for the custom emojis in the viewed channel's live chats
  /// once they're loaded. An effect: nothing depends on it, so it can read
  /// any provider.
  EmojiNameResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emojiNameResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emojiNameResolverHash();

  @$internal
  @override
  EmojiNameResolver create() => EmojiNameResolver();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$emojiNameResolverHash() => r'bd9950a2ac8d3aaccdb20118179834a9ac7c2461';

/// Looks up names for the custom emojis in the viewed channel's live chats
/// once they're loaded. An effect: nothing depends on it, so it can read
/// any provider.

abstract class _$EmojiNameResolver extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
