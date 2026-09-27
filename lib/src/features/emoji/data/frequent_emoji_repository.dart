import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/emoji_use.dart';

part 'frequent_emoji_repository.g.dart';

@Riverpod(keepAlive: true)
FrequentEmojiRepository frequentEmojiRepository(Ref ref) =>
    FrequentEmojiRepository(ref.watch(kvStorageServiceProvider));

/// Persists which emojis the user inserted into searches, for Frequently
/// Used. Corrupt entries are dropped instead of failing the load.
class FrequentEmojiRepository {
  static const _key = 'emoji.frequentlyUsed';

  final KvStorageService _kv;

  FrequentEmojiRepository(this._kv);

  Future<List<EmojiUse>> loadUses() async {
    final raw = await _kv.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?_tryDecode(item)];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveUses(List<EmojiUse> uses) async {
    await _kv.setString(
      _key,
      jsonEncode([for (final use in uses) use.toMap()]),
    );
  }

  static EmojiUse? _tryDecode(Object? item) {
    try {
      return EmojiUseMapper.fromMap(item! as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
