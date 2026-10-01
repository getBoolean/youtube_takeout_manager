import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/channel_category_repository.dart';
import '../domain/ai_result_merge.dart';
import '../domain/channel_category.dart';
import '../domain/name_key.dart';
import '../domain/sub_category.dart';
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

/// The sub-categories made for channels YouTube's don't fit, by category:
/// by AI, or typed by the user.
@Riverpod(keepAlive: true)
class CustomCategories extends _$CustomCategories {
  ChannelCategoryRepository get _repository =>
      ref.read(channelCategoryRepositoryProvider);

  @override
  Future<Map<String, List<SubCategory>>> build() =>
      ref.watch(channelCategoryRepositoryProvider).loadCustomChildren();

  /// Adds [child] under [parent], made by [origin], with [emoji] when one
  /// was picked, and keeps it, unless it's a variant of a sub-category
  /// there is, by [nameKey]: that one stays as it is, with who made it.
  /// Gives the spelling in use: YouTube's, the one kept already, or
  /// [child].
  Future<String> add(
    String parent,
    String child, {
    NameOrigin origin = NameOrigin.ai,
    String? emoji,
  }) async {
    // YouTube's alone: the taxonomy with these added is made from them.
    if (youtubeTaxonomy.find(parent, child)?.child case final youtube?) {
      return youtube;
    }
    await future;
    final current = state.requireValue;
    final existing = current[parent] ?? const <SubCategory>[];
    final key = nameKey(child);
    for (final kept in existing) {
      if (nameKey(kept.name) == key) return kept.name;
    }
    final updated = {
      ...current,
      parent: [
        ...existing,
        SubCategory(name: child, origin: origin, emoji: emoji),
      ],
    };
    state = AsyncData(updated);
    await _repository.saveCustomChildren(updated);
    return child;
  }

  /// Makes [custom] the sub-categories there are, and keeps them.
  Future<void> replaceAll(Map<String, List<SubCategory>> custom) async {
    await future;
    state = AsyncData(custom);
    await _repository.saveCustomChildren(custom);
  }
}

/// Every category: YouTube's, with the sub-categories made for channels
/// they don't fit.
@riverpod
Taxonomy categoryTaxonomy(Ref ref) => youtubeTaxonomy.withCustom(
  subCategoryNames(ref.watch(customCategoriesProvider).value ?? const {}),
);
