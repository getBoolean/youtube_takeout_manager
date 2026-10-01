import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/channel_category_repository.dart';
import '../domain/ai_result_merge.dart';
import '../domain/channel_category.dart';
import '../domain/name_key.dart';
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

  /// Sets [key]'s category to an AI run's [result], as [mergeAiResult]
  /// says: what the user decided stands, even over an answer that was
  /// already on its way.
  Future<void> putAiResult(String key, ChannelCategory result) async {
    await future;
    final current = state.requireValue;
    state = AsyncData({...current, key: mergeAiResult(current[key], result)});
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

  /// Makes [categories] every channel's, and keeps them.
  Future<void> replaceAll(Map<String, ChannelCategory> categories) async {
    await future;
    state = AsyncData(categories);
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

  /// Adds [child] under [parent] and keeps it, unless it's a variant of a
  /// sub-category there is, by [nameKey]. Gives the spelling in use:
  /// YouTube's, the one kept already, or [child].
  Future<String> add(String parent, String child) async {
    // YouTube's alone: the taxonomy with these added is made from them.
    if (youtubeTaxonomy.find(parent, child)?.child case final youtube?) {
      return youtube;
    }
    await future;
    final current = state.requireValue;
    final existing = current[parent] ?? const <String>[];
    final key = nameKey(child);
    for (final kept in existing) {
      if (nameKey(kept) == key) return kept;
    }
    final updated = {
      ...current,
      parent: [...existing, child],
    };
    state = AsyncData(updated);
    await ref
        .read(channelCategoryRepositoryProvider)
        .saveCustomChildren(updated);
    return child;
  }
}

/// Every category: YouTube's, with the sub-categories AI made.
@riverpod
Taxonomy categoryTaxonomy(Ref ref) => youtubeTaxonomy.withCustom(
  ref.watch(customCategoriesProvider).value ?? const {},
);
