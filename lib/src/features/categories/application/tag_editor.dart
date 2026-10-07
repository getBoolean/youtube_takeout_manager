import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/name_key.dart';
import '../domain/sub_category.dart';
import '../domain/tag_name.dart';
import 'channel_categories.dart';
import 'channel_tags.dart';

part 'tag_editor.g.dart';

/// The tags the user defines: a name, and a meaning that lets AI give it
/// to the channels it fits. Defining a tag or changing its meaning marks it
/// changed, so the next run checks every channel for it.
///
/// A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class TagEditor extends _$TagEditor {
  TagEditor({DateTime Function() now = DateTime.now}) : _now = now;

  final DateTime Function() _now;

  @override
  void build() {}

  /// Defines [name] as the user's, with [meaning] when given, and gives
  /// its spelling: a tag there is with the same folded name becomes the
  /// user's, keeping its spelling, and comes back if deleted.
  Future<String> define(String name, {String? meaning}) async {
    final tidy = tidyTagName(name);
    if (tidy == null) throw ArgumentError.value(name, 'name', 'is blank');
    final key = nameKey(tidy);
    final known = (await ref.read(tagNamesProvider.future))[key];
    final said = tidyTagMeaning(meaning);
    final spelled = known?.name ?? tidy;
    await ref
        .read(tagNamesProvider.notifier)
        .put(
          key,
          TagName(
            name: spelled,
            origin: NameOrigin.user,
            meaning: said ?? known?.meaning,
            changedAt: said != null && said != known?.meaning
                ? _now().toUtc()
                : known?.changedAt,
          ),
        );
    return spelled;
  }

  /// Gives the tag with the folded name [key] the [meaning] the user wrote,
  /// making it theirs; none, and AI no longer gives it to channels.
  Future<void> setMeaning(String key, String? meaning) async {
    final known = (await ref.read(tagNamesProvider.future))[key];
    if (known == null) return;
    final said = tidyTagMeaning(meaning);
    await ref
        .read(tagNamesProvider.notifier)
        .put(
          key,
          known.copyWith(
            origin: NameOrigin.user,
            meaning: said,
            changedAt: said != null && said != known.meaning
                ? _now().toUtc()
                : known.changedAt,
          ),
        );
  }

  /// Deletes the tag with the folded name [key]: it comes off every
  /// channel, even ones whose tags the user edited, and no answer brings it
  /// back.
  Future<void> delete(String key) async {
    final known = (await ref.read(tagNamesProvider.future))[key];
    await ref
        .read(tagNamesProvider.notifier)
        .put(
          key,
          TagName(
            name: known?.name ?? key,
            origin: known?.origin ?? NameOrigin.user,
            deleted: true,
          ),
        );
    await ref.read(channelCategoriesProvider.notifier).removeTag(key);
  }
}
