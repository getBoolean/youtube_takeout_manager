// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The viewed takeout's comments or live chats.

@ProviderFor(allInteractions)
final allInteractionsProvider = AllInteractionsFamily._();

/// The viewed takeout's comments or live chats.

final class AllInteractionsProvider
    extends
        $FunctionalProvider<
          List<Interaction>,
          List<Interaction>,
          List<Interaction>
        >
    with $Provider<List<Interaction>> {
  /// The viewed takeout's comments or live chats.
  AllInteractionsProvider._({
    required AllInteractionsFamily super.from,
    required QueueItemKind super.argument,
  }) : super(
         retry: null,
         name: r'allInteractionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allInteractionsHash();

  @override
  String toString() {
    return r'allInteractionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Interaction>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Interaction> create(Ref ref) {
    final argument = this.argument as QueueItemKind;
    return allInteractions(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Interaction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Interaction>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AllInteractionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allInteractionsHash() => r'af767c1448ac174e4a1c603434318a9151ab95e9';

/// The viewed takeout's comments or live chats.

final class AllInteractionsFamily extends $Family
    with $FunctionalFamilyOverride<List<Interaction>, QueueItemKind> {
  AllInteractionsFamily._()
    : super(
        retry: null,
        name: r'allInteractionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The viewed takeout's comments or live chats.

  AllInteractionsProvider call(QueueItemKind kind) =>
      AllInteractionsProvider._(argument: kind, from: this);

  @override
  String toString() => r'allInteractionsProvider';
}

/// [kind]'s items by the channel their video is on. Items whose video's
/// channel isn't known are kept under [unknownChannelId].

@ProviderFor(interactionsByChannel)
final interactionsByChannelProvider = InteractionsByChannelFamily._();

/// [kind]'s items by the channel their video is on. Items whose video's
/// channel isn't known are kept under [unknownChannelId].

final class InteractionsByChannelProvider
    extends
        $FunctionalProvider<
          Map<String, List<Interaction>>,
          Map<String, List<Interaction>>,
          Map<String, List<Interaction>>
        >
    with $Provider<Map<String, List<Interaction>>> {
  /// [kind]'s items by the channel their video is on. Items whose video's
  /// channel isn't known are kept under [unknownChannelId].
  InteractionsByChannelProvider._({
    required InteractionsByChannelFamily super.from,
    required QueueItemKind super.argument,
  }) : super(
         retry: null,
         name: r'interactionsByChannelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$interactionsByChannelHash();

  @override
  String toString() {
    return r'interactionsByChannelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<String, List<Interaction>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, List<Interaction>> create(Ref ref) {
    final argument = this.argument as QueueItemKind;
    return interactionsByChannel(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<Interaction>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<Interaction>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InteractionsByChannelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$interactionsByChannelHash() =>
    r'52ecbd740ce3661e2783b25e5ca8c7acac1e2b19';

/// [kind]'s items by the channel their video is on. Items whose video's
/// channel isn't known are kept under [unknownChannelId].

final class InteractionsByChannelFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Map<String, List<Interaction>>,
          QueueItemKind
        > {
  InteractionsByChannelFamily._()
    : super(
        retry: null,
        name: r'interactionsByChannelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// [kind]'s items by the channel their video is on. Items whose video's
  /// channel isn't known are kept under [unknownChannelId].

  InteractionsByChannelProvider call(QueueItemKind kind) =>
      InteractionsByChannelProvider._(argument: kind, from: this);

  @override
  String toString() => r'interactionsByChannelProvider';
}

/// [kind]'s items on [channelId]'s videos, newest first.

@ProviderFor(channelInteractions)
final channelInteractionsProvider = ChannelInteractionsFamily._();

/// [kind]'s items on [channelId]'s videos, newest first.

final class ChannelInteractionsProvider
    extends
        $FunctionalProvider<
          List<Interaction>,
          List<Interaction>,
          List<Interaction>
        >
    with $Provider<List<Interaction>> {
  /// [kind]'s items on [channelId]'s videos, newest first.
  ChannelInteractionsProvider._({
    required ChannelInteractionsFamily super.from,
    required (QueueItemKind, String) super.argument,
  }) : super(
         retry: null,
         name: r'channelInteractionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelInteractionsHash();

  @override
  String toString() {
    return r'channelInteractionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<Interaction>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<Interaction> create(Ref ref) {
    final argument = this.argument as (QueueItemKind, String);
    return channelInteractions(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Interaction> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Interaction>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelInteractionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelInteractionsHash() =>
    r'3b181437e88578a8289eeb9adbbea61df6c30fd7';

/// [kind]'s items on [channelId]'s videos, newest first.

final class ChannelInteractionsFamily extends $Family
    with $FunctionalFamilyOverride<List<Interaction>, (QueueItemKind, String)> {
  ChannelInteractionsFamily._()
    : super(
        retry: null,
        name: r'channelInteractionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [kind]'s items on [channelId]'s videos, newest first.

  ChannelInteractionsProvider call(QueueItemKind kind, String channelId) =>
      ChannelInteractionsProvider._(argument: (kind, channelId), from: this);

  @override
  String toString() => r'channelInteractionsProvider';
}
