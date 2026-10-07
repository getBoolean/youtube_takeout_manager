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

  /// [tags] as [resolve] has them, new ones kept with their meanings. A
  /// tag AI named without a meaning takes the one AI gives; no meaning is
  /// ever replaced, and the user's tags get none from AI.
  Future<List<String>> resolveNamed(
    Iterable<NamedTag> tags,
    NameOrigin origin,
  ) async {
    await future;
    final current = state.requireValue;
    var updated = current;
    void change(String key, TagName tag) {
      if (identical(updated, current)) updated = {...current};
      updated[key] = tag;
    }

    final resolved = <String>[];
    final keys = <String>{};
    for (final (:name, :meaning) in tags) {
      if (resolved.length == maxTags) break;
      final tidy = tidyTagName(name);
      if (tidy == null) continue;
      final key = nameKey(tidy);
      if (!keys.add(key)) continue;
      final said = tidyTagMeaning(meaning);
      if (updated[key] case final known?) {
        if (known.deleted) continue;
        if (said != null &&
            known.meaning == null &&
            known.origin == NameOrigin.ai &&
            origin == NameOrigin.ai) {
          change(key, known.copyWith(meaning: said));
        }
        resolved.add(known.name);
        continue;
      }
      change(key, TagName(name: tidy, origin: origin, meaning: said));
      resolved.add(tidy);
    }
    if (!identical(updated, current)) {
      state = AsyncData(updated);
      await _repository.saveTags(updated);
    }
    return resolved;
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
