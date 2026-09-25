// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_in_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The YouTube channel of the signed-in Google account, or null when signed
/// out. Throws if it can't be looked up or the account has no channel.
///
/// Failures aren't retried automatically, so an import waiting on this fails
/// right away; invalidate it to look the channel up again.

@ProviderFor(signedInChannelId)
final signedInChannelIdProvider = SignedInChannelIdProvider._();

/// The YouTube channel of the signed-in Google account, or null when signed
/// out. Throws if it can't be looked up or the account has no channel.
///
/// Failures aren't retried automatically, so an import waiting on this fails
/// right away; invalidate it to look the channel up again.

final class SignedInChannelIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The YouTube channel of the signed-in Google account, or null when signed
  /// out. Throws if it can't be looked up or the account has no channel.
  ///
  /// Failures aren't retried automatically, so an import waiting on this fails
  /// right away; invalidate it to look the channel up again.
  SignedInChannelIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'signedInChannelIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signedInChannelIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return signedInChannelId(ref);
  }
}

String _$signedInChannelIdHash() => r'4d8d9863f37e2792fe2fd49643076d34af703555';
