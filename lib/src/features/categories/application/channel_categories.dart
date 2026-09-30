import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/channel_category_repository.dart';
import '../domain/channel_category.dart';
import '../domain/youtube_taxonomy.dart';

part 'channel_categories.g.dart';

/// Channels' categories, by channel key, kept on this device. Made by
/// `ChannelCategorizer`.
@Riverpod(keepAlive: true)
class ChannelCategories extends _$ChannelCategories {
  ChannelCategoryRepository get _repository =>
      ref.read(channelCategoryRepositoryProvider);

  @override
  Future<Map<String, ChannelCategory>> build() =>
      ref.watch(channelCategoryRepositoryProvider).loadCategories();

  /// Sets [key]'s category, unless the user accepted or denied one for it:
  /// what they said stands, even over an answer that was already on its way.
  Future<void> putIfUndecided(String key, ChannelCategory category) async {
    await future;
    final current = state.requireValue;
    if ((current[key]?.userDecision ?? UserDecision.none) !=
        UserDecision.none) {
      return;
    }
    state = AsyncData({...current, key: category});
  }

  /// Adds [categories] for the channels that have none yet, at once.
  Future<void> addMissing(Map<String, ChannelCategory> categories) async {
    await future;
    final current = state.requireValue;
    final missing = {
      for (final MapEntry(:key, :value) in categories.entries)
        if (!current.containsKey(key)) key: value,
    };
    if (missing.isNotEmpty) state = AsyncData({...current, ...missing});
  }

  /// Sets [key]'s category as the user decided it, and keeps it.
  Future<void> decide(String key, ChannelCategory category) async {
    await future;
    state = AsyncData({...state.requireValue, key: category});
    await persist();
  }

  /// Keeps the categories on this device.
  Future<void> persist() => _repository.saveCategories(state.value ?? const {});
}

/// The sub-categories AI made for channels YouTube's don't fit, by category.
@Riverpod(keepAlive: true)
class CustomCategories extends _$CustomCategories {
  @override
  Future<Map<String, List<String>>> build() =>
      ref.watch(channelCategoryRepositoryProvider).loadCustomChildren();

  /// Adds [child] under [parent], once whatever its case, and keeps it.
  Future<void> add(String parent, String child) async {
    await future;
    final current = state.requireValue;
    final existing = current[parent] ?? const <String>[];
    if (existing.any((c) => c.toLowerCase() == child.toLowerCase())) return;
    final updated = {
      ...current,
      parent: [...existing, child],
    };
    state = AsyncData(updated);
    await ref
        .read(channelCategoryRepositoryProvider)
        .saveCustomChildren(updated);
  }
}

/// Every category: YouTube's, with the sub-categories AI made.
@riverpod
Taxonomy categoryTaxonomy(Ref ref) => youtubeTaxonomy.withCustom(
  ref.watch(customCategoriesProvider).value ?? const {},
);
