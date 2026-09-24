// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_emoji_name_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(youtubeEmojiNameRepository)
final youtubeEmojiNameRepositoryProvider =
    YoutubeEmojiNameRepositoryProvider._();

final class YoutubeEmojiNameRepositoryProvider
    extends
        $FunctionalProvider<
          YoutubeEmojiNameRepository,
          YoutubeEmojiNameRepository,
          YoutubeEmojiNameRepository
        >
    with $Provider<YoutubeEmojiNameRepository> {
  YoutubeEmojiNameRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'youtubeEmojiNameRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$youtubeEmojiNameRepositoryHash();

  @$internal
  @override
  $ProviderElement<YoutubeEmojiNameRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  YoutubeEmojiNameRepository create(Ref ref) {
    return youtubeEmojiNameRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(YoutubeEmojiNameRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<YoutubeEmojiNameRepository>(value),
    );
  }
}

String _$youtubeEmojiNameRepositoryHash() =>
    r'f3dd3e56d03b7abd5e8f2911621b8c2562355a58';
