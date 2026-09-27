import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/frequent_emoji_repository.dart';
import '../domain/emoji_use.dart';

part 'frequent_emojis.g.dart';

const _maxFrequentEmojis = 50;

/// Emojis the user inserted into a search, most used first (ties: most
/// recent). Once full, the least recently used entry makes room for a new one.
@Riverpod(keepAlive: true)
class FrequentEmojis extends _$FrequentEmojis {
  FrequentEmojiRepository get _repository =>
      ref.read(frequentEmojiRepositoryProvider);

  @override
  Future<List<EmojiUse>> build() async {
    final uses = await ref.watch(frequentEmojiRepositoryProvider).loadUses();
    return [...uses]..sort(_byUse);
  }

  static int _byUse(EmojiUse a, EmojiUse b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : b.lastUsed.compareTo(a.lastUsed);
  }

  /// Records that the emoji with this `PickerEmoji.usageId` was inserted.
  Future<void> recordUse(String id) async {
    final current = await future;
    final previous = current.where((u) => u.id == id).firstOrNull;
    final uses = [
      for (final use in current)
        if (use.id != id) use,
    ];
    if (uses.length >= _maxFrequentEmojis) {
      uses.remove(
        uses.reduce((a, b) => a.lastUsed.isBefore(b.lastUsed) ? a : b),
      );
    }
    uses
      ..add(
        EmojiUse(
          id: id,
          count: (previous?.count ?? 0) + 1,
          lastUsed: DateTime.now(),
        ),
      )
      ..sort(_byUse);
    state = AsyncData(uses);
    await _repository.saveUses(uses);
  }
}
