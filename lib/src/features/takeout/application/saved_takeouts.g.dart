// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_takeouts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data. Removing one is `TakeoutRemover`'s.

@ProviderFor(SavedTakeouts)
final savedTakeoutsProvider = SavedTakeoutsProvider._();

/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data. Removing one is `TakeoutRemover`'s.
final class SavedTakeoutsProvider
    extends $AsyncNotifierProvider<SavedTakeouts, List<TakeoutSummary>> {
  /// Every saved takeout, newest export first, read from each one's small
  /// summary files rather than all its data. The loaded takeout's comes from
  /// its data. Removing one is `TakeoutRemover`'s.
  SavedTakeoutsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedTakeoutsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedTakeoutsHash();

  @$internal
  @override
  SavedTakeouts create() => SavedTakeouts();
}

String _$savedTakeoutsHash() => r'71f75e87e7616c37378dc15cb89f3b269b92527c';

/// Every saved takeout, newest export first, read from each one's small
/// summary files rather than all its data. The loaded takeout's comes from
/// its data. Removing one is `TakeoutRemover`'s.

abstract class _$SavedTakeouts extends $AsyncNotifier<List<TakeoutSummary>> {
  FutureOr<List<TakeoutSummary>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<TakeoutSummary>>, List<TakeoutSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TakeoutSummary>>,
                List<TakeoutSummary>
              >,
              AsyncValue<List<TakeoutSummary>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The saved takeout that has [channelId], or null if none does.

@ProviderFor(savedTakeoutWithChannel)
final savedTakeoutWithChannelProvider = SavedTakeoutWithChannelFamily._();

/// The saved takeout that has [channelId], or null if none does.

final class SavedTakeoutWithChannelProvider
    extends
        $FunctionalProvider<TakeoutSummary?, TakeoutSummary?, TakeoutSummary?>
    with $Provider<TakeoutSummary?> {
  /// The saved takeout that has [channelId], or null if none does.
  SavedTakeoutWithChannelProvider._({
    required SavedTakeoutWithChannelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'savedTakeoutWithChannelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedTakeoutWithChannelHash();

  @override
  String toString() {
    return r'savedTakeoutWithChannelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TakeoutSummary?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TakeoutSummary? create(Ref ref) {
    final argument = this.argument as String;
    return savedTakeoutWithChannel(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TakeoutSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TakeoutSummary?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SavedTakeoutWithChannelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedTakeoutWithChannelHash() =>
    r'713c4bf40c0a3c2c1e31968e1c8b82ac7ee236bb';

/// The saved takeout that has [channelId], or null if none does.

final class SavedTakeoutWithChannelFamily extends $Family
    with $FunctionalFamilyOverride<TakeoutSummary?, String> {
  SavedTakeoutWithChannelFamily._()
    : super(
        retry: null,
        name: r'savedTakeoutWithChannelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The saved takeout that has [channelId], or null if none does.

  SavedTakeoutWithChannelProvider call(String channelId) =>
      SavedTakeoutWithChannelProvider._(argument: channelId, from: this);

  @override
  String toString() => r'savedTakeoutWithChannelProvider';
}
