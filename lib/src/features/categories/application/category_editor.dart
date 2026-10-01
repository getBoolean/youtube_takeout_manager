import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import '../domain/category_path.dart';
import '../domain/category_prompts.dart';
import '../domain/channel_category.dart';
import '../domain/sub_category.dart';
import 'channel_categories.dart';
import 'channel_categorizer.dart';
import 'channel_tags.dart';

part 'category_editor.g.dart';

/// What the user decides about a channel's category and tags, kept: an AI
/// suggestion used or the category kept, YouTube's category used, one
/// chosen or typed in, and tags added or removed. Nothing the user decides
/// is changed by categorizing later.
///
/// A service: nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class CategoryEditor extends _$CategoryEditor {
  @override
  void build() {}

  /// Makes [suggestion] [channel]'s category, as the user chose, keeping a
  /// new sub-category it names, with the emoji AI gave it; and the tags it
  /// brings, as the user's, unless they edited the ones there are.
  Future<void> accept(
    HistoryChannel channel,
    ChannelCategory suggestion,
  ) async {
    final current = await _current(channel);
    var path = suggestion.path;
    if (path != null) {
      final emoji = ref
          .read(channelCategorizerProvider.notifier)
          .suggestedEmoji(path);
      path = await _spelled(path, origin: NameOrigin.ai, emoji: emoji);
    }
    var accepted = suggestion.copyWith(
      path: path,
      userDecision: UserDecision.accepted,
      decidedAt: DateTime.now().toUtc(),
    );
    if ((current?.tagsEditedByUser ?? false) ||
        !suggestion.tagsTried ||
        suggestion.tags.isEmpty) {
      accepted = accepted.copyWith(
        tags: current?.tags ?? const [],
        tagsTried: current?.tagsTried ?? false,
        tagsEditedByUser: current?.tagsEditedByUser ?? false,
        tagsPrompt: current?.tagsPrompt,
      );
    } else {
      // A suggestion the user took is theirs, tags and all.
      accepted = accepted.copyWith(
        tags: await ref
            .read(tagNamesProvider.notifier)
            .resolve(suggestion.tags, NameOrigin.ai),
        tagsEditedByUser: true,
      );
    }
    await _decide(channel, accepted);
  }

  /// Keeps [channel]'s category as it is, as the user chose: nothing
  /// replaces it.
  Future<void> deny(HistoryChannel channel) async {
    final now = DateTime.now().toUtc();
    final current = await _current(channel);
    await _decide(
      channel,
      (current ?? ChannelCategory(decidedAt: now)).copyWith(
        userDecision: UserDecision.denied,
        decidedAt: now,
      ),
    );
  }

  /// Makes [youtube], the category YouTube's topics give, [channel]'s, as
  /// the user chose, keeping its tags.
  Future<void> useYouTube(HistoryChannel channel, CategoryPath youtube) =>
      _set(channel, youtube, CategorySource.youtube);

  /// Makes [path] [channel]'s category, as the user chose it, keeping its
  /// tags.
  Future<void> choose(HistoryChannel channel, CategoryPath path) async => _set(
    channel,
    await _spelled(path, origin: NameOrigin.user),
    CategorySource.user,
  );

  /// Adds the sub-category the user typed, [name], under [parent], with
  /// the [emoji] they picked; or, when it's a variant of one there is, that
  /// one as it is. Gives it as spelled.
  Future<CategoryPath> addSubCategory(
    String parent,
    String name, {
    String? emoji,
  }) async {
    final tidy = normalizeChildName(name);
    if (tidy == null) return CategoryPath(parent);
    return _spelled(
      CategoryPath(parent, tidy),
      origin: NameOrigin.user,
      emoji: emoji,
    );
  }

  /// Makes [tags] [channel]'s, as the user's: spelled as the tags there are
  /// spell them, new ones made by the user, at most [maxTags].
  Future<void> setTags(HistoryChannel channel, List<String> tags) async {
    final current = await _current(channel);
    final resolved = await ref
        .read(tagNamesProvider.notifier)
        .resolve(tags, NameOrigin.user);
    await _decide(
      channel,
      (current ?? ChannelCategory(decidedAt: DateTime.now().toUtc())).copyWith(
        tags: resolved,
        tagsTried: true,
        tagsEditedByUser: true,
      ),
    );
  }

  Future<void> _set(
    HistoryChannel channel,
    CategoryPath path,
    CategorySource source,
  ) async {
    final now = DateTime.now().toUtc();
    final current = await _current(channel);
    await _decide(
      channel,
      (current ?? ChannelCategory(decidedAt: now)).copyWith(
        path: path,
        source: source,
        userDecision: UserDecision.accepted,
        jevAgreed: null,
        confidence: null,
        runnersUp: const [],
        reason: null,
        decidedAt: now,
      ),
    );
  }

  /// [path] as spelled where it's there already; a sub-category that isn't
  /// is added, made by [origin], with [emoji].
  Future<CategoryPath> _spelled(
    CategoryPath path, {
    required NameOrigin origin,
    String? emoji,
  }) async {
    await ref.read(customCategoriesProvider.future);
    final taxonomy = ref.read(categoryTaxonomyProvider);
    final found = taxonomy.find(path.parent, path.child);
    if (found != null) return found;
    final parent = taxonomy.find(path.parent)?.parent ?? path.parent;
    final child = path.child;
    if (child == null) return CategoryPath(parent);
    return CategoryPath(
      parent,
      await ref
          .read(customCategoriesProvider.notifier)
          .add(parent, child, origin: origin, emoji: emoji),
    );
  }

  Future<ChannelCategory?> _current(HistoryChannel channel) async =>
      (await ref.read(channelCategoriesProvider.future))[channel.key];

  Future<void> _decide(HistoryChannel channel, ChannelCategory category) => ref
      .read(channelCategoriesProvider.notifier)
      .decide(channel.key, category);
}
