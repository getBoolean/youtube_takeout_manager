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
  /// once, blanks left out, at most [maxTags].
  Future<List<String>> resolve(
    Iterable<String> names,
    NameOrigin origin,
  ) async {
    await future;
    final current = state.requireValue;
    var updated = current;
    final resolved = <String>[];
    final keys = <String>{};
    for (final name in names) {
      if (resolved.length == maxTags) break;
      final tidy = tidyTagName(name);
      if (tidy == null) continue;
      final key = nameKey(tidy);
      if (!keys.add(key)) continue;
      if (updated[key] case final known?) {
        resolved.add(known.name);
        continue;
      }
      if (identical(updated, current)) updated = {...current};
      updated[key] = TagName(name: tidy, origin: origin);
      resolved.add(tidy);
    }
    if (!identical(updated, current)) {
      state = AsyncData(updated);
      await _repository.saveTags(updated);
    }
    return resolved;
  }

  /// Makes [tags] every tag there is, and keeps them.
  Future<void> replaceAll(Map<String, TagName> tags) async {
    await future;
    state = AsyncData(tags);
    await _repository.saveTags(tags);
  }
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
