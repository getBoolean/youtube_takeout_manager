// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_categorizer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Categorizes the channels watched and subscribed to, the most watched
/// first, once the history screen has been opened. Signed in, it first asks
/// YouTube for the topics of channels it doesn't know them for. A category
/// the user accepted or denied is never replaced. Starts over when the
/// history, subscriptions or sign-in change, dropping the run under way.
///
/// A service: nothing depends on it, so it can read any provider.

@ProviderFor(ChannelCategorizer)
final channelCategorizerProvider = ChannelCategorizerProvider._();

/// Categorizes the channels watched and subscribed to, the most watched
/// first, once the history screen has been opened. Signed in, it first asks
/// YouTube for the topics of channels it doesn't know them for. A category
/// the user accepted or denied is never replaced. Starts over when the
/// history, subscriptions or sign-in change, dropping the run under way.
///
/// A service: nothing depends on it, so it can read any provider.
final class ChannelCategorizerProvider
    extends $NotifierProvider<ChannelCategorizer, void> {
  /// Categorizes the channels watched and subscribed to, the most watched
  /// first, once the history screen has been opened. Signed in, it first asks
  /// YouTube for the topics of channels it doesn't know them for. A category
  /// the user accepted or denied is never replaced. Starts over when the
  /// history, subscriptions or sign-in change, dropping the run under way.
  ///
  /// A service: nothing depends on it, so it can read any provider.
  ChannelCategorizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelCategorizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelCategorizerHash();

  @$internal
  @override
  ChannelCategorizer create() => ChannelCategorizer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$channelCategorizerHash() =>
    r'02e3957faa72338d78c2495453bad9e5b75d2e4c';

/// Categorizes the channels watched and subscribed to, the most watched
/// first, once the history screen has been opened. Signed in, it first asks
/// YouTube for the topics of channels it doesn't know them for. A category
/// the user accepted or denied is never replaced. Starts over when the
/// history, subscriptions or sign-in change, dropping the run under way.
///
/// A service: nothing depends on it, so it can read any provider.

abstract class _$ChannelCategorizer extends $Notifier<void> {
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
