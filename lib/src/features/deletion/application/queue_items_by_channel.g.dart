// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_items_by_channel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The channel each queued comment or live chat was posted on, by item ID,
/// grouped the same way as the channel lists. Items whose channel is
/// unknown, or that are no longer in the takeout, are missing.

@ProviderFor(queuedItemChannelIds)
final queuedItemChannelIdsProvider = QueuedItemChannelIdsProvider._();

/// The channel each queued comment or live chat was posted on, by item ID,
/// grouped the same way as the channel lists. Items whose channel is
/// unknown, or that are no longer in the takeout, are missing.

final class QueuedItemChannelIdsProvider
    extends
        $FunctionalProvider<
          Map<String, String>,
          Map<String, String>,
          Map<String, String>
        >
    with $Provider<Map<String, String>> {
  /// The channel each queued comment or live chat was posted on, by item ID,
  /// grouped the same way as the channel lists. Items whose channel is
  /// unknown, or that are no longer in the takeout, are missing.
  QueuedItemChannelIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'queuedItemChannelIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queuedItemChannelIdsHash();

  @$internal
  @override
  $ProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, String> create(Ref ref) {
    return queuedItemChannelIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$queuedItemChannelIdsHash() =>
    r'c00ce74b93e361b1cb2385029f2b4cd2912d0bd8';
