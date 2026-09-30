import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';
import '../domain/channel_category.dart';

part 'channel_category_repository.g.dart';

@Riverpod(keepAlive: true)
ChannelCategoryRepository channelCategoryRepository(Ref ref) =>
    ChannelCategoryRepository(ref.watch(kvStorageServiceProvider));

const _categoriesKey = 'channel_categories';
const _customChildrenKey = 'custom_category_children';

/// Keeps channels' categories on this device, by channel, whichever
/// takeout they're in, and the sub-categories AI made. Clearing the cache
/// keeps them: AI ones cost money to make again.
class ChannelCategoryRepository {
  final KvStorageService _kv;

  ChannelCategoryRepository(this._kv);

  /// Categories that can't be read are skipped, keeping the rest.
  Future<Map<String, ChannelCategory>> loadCategories() async {
    final json = await _kv.getString(_categoriesKey);
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return {
      for (final MapEntry(:key, :value) in map.entries) key: ?_read(value),
    };
  }

  static ChannelCategory? _read(Object? value) {
    try {
      return ChannelCategoryMapper.fromMap(value! as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> saveCategories(Map<String, ChannelCategory> categories) =>
      _kv.setString(
        _categoriesKey,
        jsonEncode({
          for (final MapEntry(:key, :value) in categories.entries)
            key: value.toMap(),
        }),
      );

  /// The sub-categories AI made, by category.
  Future<Map<String, List<String>>> loadCustomChildren() async {
    final json = await _kv.getString(_customChildrenKey);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in map.entries)
          key: (value as List<dynamic>).cast<String>(),
      };
    } on Object {
      return {};
    }
  }

  Future<void> saveCustomChildren(Map<String, List<String>> children) =>
      _kv.setString(_customChildrenKey, jsonEncode(children));
}
