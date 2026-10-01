import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categorizing_channels.g.dart';

/// The keys of the channels categorizing is asking AI about right now, so
/// asking about one of them again can wait.
@Riverpod(keepAlive: true)
class CategorizingChannels extends _$CategorizingChannels {
  @override
  Set<String> build() => const {};

  void add(String key) => state = {...state, key};

  void remove(String key) {
    if (state.contains(key)) state = {...state}..remove(key);
  }
}
