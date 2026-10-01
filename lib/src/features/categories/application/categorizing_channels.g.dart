// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorizing_channels.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The keys of the channels categorizing is asking AI about right now, so
/// asking about one of them again can wait.

@ProviderFor(CategorizingChannels)
final categorizingChannelsProvider = CategorizingChannelsProvider._();

/// The keys of the channels categorizing is asking AI about right now, so
/// asking about one of them again can wait.
final class CategorizingChannelsProvider
    extends $NotifierProvider<CategorizingChannels, Set<String>> {
  /// The keys of the channels categorizing is asking AI about right now, so
  /// asking about one of them again can wait.
  CategorizingChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categorizingChannelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorizingChannelsHash();

  @$internal
  @override
  CategorizingChannels create() => CategorizingChannels();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$categorizingChannelsHash() =>
    r'8bb254ef7b1c348a8ac3a9c3d4e15f5de858c586';

/// The keys of the channels categorizing is asking AI about right now, so
/// asking about one of them again can wait.

abstract class _$CategorizingChannels extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
