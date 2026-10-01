import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import '../domain/channel_category.dart';
import '../domain/name_merge.dart';
import '../domain/sub_category.dart';

part 'channel_category_repository.g.dart';

@Riverpod(keepAlive: true)
ChannelCategoryRepository channelCategoryRepository(Ref ref) =>
    ChannelCategoryRepository(ref.watch(entryStoreProvider));

/// Keeps channels' categories on this device, by channel, whichever
/// takeout they're in, and the sub-categories AI made. Clearing the cache
/// keeps them: AI ones cost money to make again. The first loads of a
/// session merge sub-category names that differ only by case, accents,
/// hyphens, spaces or punctuation, and keep the merge.
class ChannelCategoryRepository {
  final EntryBox<ChannelCategory> _categories;
  final EntryBox<List<SubCategory>> _custom;

  /// Both boxes, merged, until each has been loaded from it once.
  Future<StoredNames>? _merged;
  var _categoriesServed = false;
  var _customServed = false;

  ChannelCategoryRepository(EntryStore store)
    : _categories = EntryBox(
        store,
        EntryBoxes.channelCategories,
        encode: (category) => category.toMap(),
        decode: (json) =>
            ChannelCategoryMapper.fromMap(json! as Map<String, dynamic>),
      ),
      _custom = EntryBox(
        store,
        EntryBoxes.customSubCategories,
        encode: (children) => [for (final child in children) child.toMap()],
        decode: (json) => [
          for (final child in json! as List<dynamic>)
            SubCategory.fromStored(child),
        ],
      );

  /// Categories that can't be read are skipped, keeping the rest.
  Future<Map<String, ChannelCategory>> loadCategories() async {
    if (_categoriesServed) return _categories.load();
    final merged = await _merge();
    _categoriesServed = true;
    return merged.categories;
  }

  Future<void> saveCategories(Map<String, ChannelCategory> categories) =>
      _categories.save(categories);

  /// The sub-categories made for channels YouTube's don't fit, by
  /// category.
  Future<Map<String, List<SubCategory>>> loadCustomChildren() async {
    if (_customServed) return _custom.load();
    final merged = await _merge();
    _customServed = true;
    return merged.custom;
  }

  Future<void> saveCustomChildren(Map<String, List<SubCategory>> children) =>
      _custom.save(children);

  /// Both boxes with name variants merged, the merge kept: categories
  /// first, then the AI-made list, each writing only what changed. A merge
  /// that can't be kept is still given, and made again next time.
  Future<StoredNames> _merge() => _merged ??= () async {
    final StoredNames merged;
    try {
      merged = mergeNameVariants((
        categories: await _categories.load(),
        custom: await _custom.load(),
      ));
    } on Object {
      _merged = null;
      rethrow;
    }
    try {
      await _categories.save(merged.categories);
      await _custom.save(merged.custom);
    } on Object {
      _merged = null;
    }
    return merged;
  }();
}
