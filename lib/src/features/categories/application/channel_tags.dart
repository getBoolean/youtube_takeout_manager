import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/channel_category_repository.dart';
import '../domain/channel_category.dart';
import '../domain/name_key.dart';
import '../domain/sub_category.dart';
import '../domain/tag_name.dart';
import 'channel_categories.dart';

part 'channel_tags.g.dart';

/// Every tag there is, as first spelled, with who made it, by its folded
/// name ([nameKey]), kept on this device.
@Riverpod(keepAlive: true)
class TagNames extends _$TagNames {
  ChannelCategoryRepository get _repository =>
      ref.read(channelCategoryRepositoryProvider);

  @override
  Future<Map<String, TagName>> build() =>
      ref.watch(channelCategoryRepositoryProvider).loadTags();

  /// [names] tidied, each spelled as the tag there is with the same folded
  /// name, the rest added as made by [origin] and kept; in order, each
  /// once, blanks and deleted tags left out, at most [maxTags].
  Future<List<String>> resolve(Iterable<String> names, NameOrigin origin) =>
      resolveNamed([
        for (final name in names) (name: name, meaning: null),
      ], origin);

  /// [tags] as [resolve] has them, new ones kept with their meanings, as
  /// [mergeNamedTags] merges them, saved when they change the tags there
  /// are.
  Future<List<String>> resolveNamed(
    Iterable<NamedTag> tags,
    NameOrigin origin,
  ) async {
    await future;
    final current = state.requireValue;
    final merged = mergeNamedTags(current, tags, origin);
    if (!identical(merged.names, current)) {
      state = AsyncData(merged.names);
      await _repository.saveTags(merged.names);
    }
    return merged.resolved;
  }

  /// Keeps [tag] as the one with the folded name [key].
  Future<void> put(String key, TagName tag) async {
    await future;
    final updated = {...state.requireValue, key: tag};
    state = AsyncData(updated);
    await _repository.saveTags(updated);
  }

  /// Makes [tags] every tag there is, and keeps them.
  Future<void> replaceAll(Map<String, TagName> tags) async {
    await future;
    state = AsyncData(tags);
    await _repository.saveTags(tags);
  }
}

/// A tag kept, by its folded name, and how many channels have it.
typedef KeptTag = ({String key, TagName tag, int channels});

/// Every tag kept and not deleted, with how many channels have it: the
/// user's first, then the most used, ties by name.
@riverpod
List<KeptTag> tagRegistry(Ref ref) {
  final categories = ref.watch(channelCategoriesProvider).value ?? const {};
  final names = ref.watch(tagNamesProvider).value ?? const {};
  final counts = <String, int>{};
  final spellings = <String, String>{};
  for (final category in categories.values) {
    for (final tag in category.tags) {
      final key = nameKey(tag);
      counts[key] = (counts[key] ?? 0) + 1;
      spellings.putIfAbsent(key, () => tag);
    }
  }
  int rank(TagName tag) => tag.origin == NameOrigin.user ? 0 : 1;
  return [
    for (final MapEntry(:key, value: tag) in names.entries)
      if (!tag.deleted) (key: key, tag: tag, channels: counts[key] ?? 0),
    for (final MapEntry(:key, value: channels) in counts.entries)
      if (!names.containsKey(key))
        (key: key, tag: TagName(name: spellings[key]!), channels: channels),
  ]..sort((a, b) {
    final byOrigin = rank(a.tag).compareTo(rank(b.tag));
    if (byOrigin != 0) return byOrigin;
    final byUse = b.channels.compareTo(a.channels);
    return byUse != 0 ? byUse : a.tag.name.compareTo(b.tag.name);
  });
}

/// A tag, how many channels have it, and who made it.
typedef TagUse = ({String name, int channels, NameOrigin origin});

/// Every tag channels have, the most used first, ties by name.
@riverpod
List<TagUse> tagUsage(Ref ref) {
  final categories = ref.watch(channelCategoriesProvider).value ?? const {};
  final names = ref.watch(tagNamesProvider).value ?? const {};
  final counts = <String, int>{};
  final spellings = <String, String>{};
  for (final category in categories.values) {
    for (final tag in category.tags) {
      final key = nameKey(tag);
      counts[key] = (counts[key] ?? 0) + 1;
      spellings.putIfAbsent(key, () => names[key]?.name ?? tag);
    }
  }
  return [
    for (final MapEntry(:key, value: channels) in counts.entries)
      (
        name: spellings[key]!,
        channels: channels,
        origin: names[key]?.origin ?? NameOrigin.ai,
      ),
  ]..sort((a, b) {
    final byUse = b.channels.compareTo(a.channels);
    return byUse != 0 ? byUse : a.name.compareTo(b.name);
  });
}
