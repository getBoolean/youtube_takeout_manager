import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/entry_box.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';
import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';
import '../domain/channel_category.dart';

part 'channel_category_repository.g.dart';

@Riverpod(keepAlive: true)
ChannelCategoryRepository channelCategoryRepository(Ref ref) =>
    ChannelCategoryRepository(ref.watch(entryStoreProvider));

/// Keeps channels' categories on this device, by channel, whichever
/// takeout they're in, and the sub-categories AI made. Clearing the cache
/// keeps them: AI ones cost money to make again.
class ChannelCategoryRepository {
  final EntryBox<ChannelCategory> _categories;
  final EntryBox<List<String>> _custom;

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
        encode: (children) => children,
        decode: (json) => (json! as List<dynamic>).cast<String>(),
      );

  /// Categories that can't be read are skipped, keeping the rest.
  Future<Map<String, ChannelCategory>> loadCategories() => _categories.load();

  Future<void> saveCategories(Map<String, ChannelCategory> categories) =>
      _categories.save(categories);

  /// The sub-categories AI made, by category.
  Future<Map<String, List<String>>> loadCustomChildren() => _custom.load();

  Future<void> saveCustomChildren(Map<String, List<String>> children) =>
      _custom.save(children);
}
