// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_content_search_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search text on the channel detail screen, shared by the comments and live
/// chats tabs.

@ProviderFor(ChannelContentSearchQuery)
final channelContentSearchQueryProvider = ChannelContentSearchQueryProvider._();

/// Search text on the channel detail screen, shared by the comments and live
/// chats tabs.
final class ChannelContentSearchQueryProvider
    extends $NotifierProvider<ChannelContentSearchQuery, String> {
  /// Search text on the channel detail screen, shared by the comments and live
  /// chats tabs.
  ChannelContentSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelContentSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelContentSearchQueryHash();

  @$internal
  @override
  ChannelContentSearchQuery create() => ChannelContentSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$channelContentSearchQueryHash() =>
    r'e7252e042fbb6f1aa10645d2219b1092bab6afc4';

/// Search text on the channel detail screen, shared by the comments and live
/// chats tabs.

abstract class _$ChannelContentSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
