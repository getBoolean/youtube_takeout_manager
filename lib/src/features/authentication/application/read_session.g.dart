// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The channel whose sign-in loads public details like video titles and
/// channel avatars: the viewed channel's, else any saved one, else null.
///
/// These reads don't act on any channel, so a signed-out or deleted channel
/// still gets titles while any sign-in is saved. Deleting only ever uses the
/// viewed channel's own sign-in.

@ProviderFor(readSessionChannelId)
final readSessionChannelIdProvider = ReadSessionChannelIdProvider._();

/// The channel whose sign-in loads public details like video titles and
/// channel avatars: the viewed channel's, else any saved one, else null.
///
/// These reads don't act on any channel, so a signed-out or deleted channel
/// still gets titles while any sign-in is saved. Deleting only ever uses the
/// viewed channel's own sign-in.

final class ReadSessionChannelIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The channel whose sign-in loads public details like video titles and
  /// channel avatars: the viewed channel's, else any saved one, else null.
  ///
  /// These reads don't act on any channel, so a signed-out or deleted channel
  /// still gets titles while any sign-in is saved. Deleting only ever uses the
  /// viewed channel's own sign-in.
  ReadSessionChannelIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readSessionChannelIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readSessionChannelIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return readSessionChannelId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$readSessionChannelIdHash() =>
    r'270dd57b18de9191fce57a8596035199baa0887b';
