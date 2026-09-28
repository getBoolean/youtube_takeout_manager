import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/history_merge.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'channel_id.dart';
import 'own_channel.dart';
import 'subscription.dart';
import 'takeout_channel.dart';
import 'takeout_data.dart';
import 'takeout_export.dart';
import 'takeout_import_plan.dart';
import 'takeout_import_request.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// Merges [exports], the picked takeouts read, with the saved data and works
/// out which items are no longer on YouTube.
///
/// For each kind, the account's items missing from the newest source of
/// that kind are gone, unless they were created after that source was
/// exported. Their watch and search history is merged into [savedHistory],
/// the saved takeout's, when merging. Throws a [TakeoutImportException] when
/// they can't be imported safely.
TakeoutImportPlan planTakeoutImport(
  List<TakeoutExport> exports,
  TakeoutImportContext context, {
  TakeoutHistory? savedHistory,
}) {
  if (exports.isEmpty) {
    throw ArgumentError.value(exports, 'exports', 'No takeouts to import');
  }
  final base = context.merge ? context.saved : null;
  final picked = [for (final e in exports) _Source.export(e)];
  final (id: accountId, :accountAssumed) = _resolveTakeout(picked, context);

  final sources = [if (base != null) _Source.saved(base), ...picked]
    ..sort((a, b) => _compareSnapshots(a.snapshot, a, b.snapshot, b));

  final comments = <String, Comment>{};
  final liveChats = <String, LiveChat>{};
  final subscriptions = <String, Subscription>{};
  final ownChannels = <String, OwnChannel>{};
  for (final source in sources) {
    for (final c in source.data.comments) {
      comments[c.commentId] = c;
    }
    for (final l in source.data.liveChats) {
      liveChats[l.liveChatId] = l;
    }
    subscriptions.addAll(source.data.subscriptionsByChannelId);
    ownChannels.addAll(source.data.ownChannels);
  }

  final newestComments = _newestWith(sources, (s) => s.comments);
  final newestLiveChats = _newestWith(sources, (s) => s.liveChats);
  // Only channels in the newest source can have items found gone: a channel
  // moved to another account isn't in newer takeouts, but its items aren't
  // gone. Rows without a Channel ID count as the channel the takeout is
  // saved under, even when its channel.csv names another main channel.
  bool inSource(_Newest? newest, String author) =>
      newest != null &&
      newest.channels.contains(
        authorChannelId(author, mainChannelId: accountId),
      );
  final goneComments = _findGone(newestComments, {
    for (final c in comments.values)
      if (inSource(newestComments, c.channelId)) c.commentId: c.createdAt,
  });
  final goneLiveChats = _findGone(newestLiveChats, {
    for (final l in liveChats.values)
      if (inSource(newestLiveChats, l.channelId)) l.liveChatId: l.createdAt,
  });

  final mergedData = TakeoutData(
    comments: comments.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    liveChats: liveChats.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    subscriptionsByChannelId: subscriptions,
    skippedCommentRows: _sum(picked, (e) => e.data.skippedCommentRows),
    skippedLiveChatRows: _sum(picked, (e) => e.data.skippedLiveChatRows),
    latestExportAt: sources.last.snapshot,
    commentsSnapshot: newestComments?.snapshot,
    liveChatsSnapshot: newestLiveChats?.snapshot,
    ownChannels: ownChannels,
  );

  final baseCommentIds = {...?base?.comments.map((c) => c.commentId)};
  final baseLiveChatIds = {...?base?.liveChats.map((l) => l.liveChatId)};
  return TakeoutImportPlan(
    accountId: accountId,
    mergedData: mergedData,
    channels: takeoutChannelsOf(mergedData, takeoutId: accountId),
    goneCommentIds: goneComments.ids,
    goneLiveChatIds: goneLiveChats.ids,
    newlyDeletedCommentIds: goneComments.ids.difference(
      context.deletedCommentIds,
    ),
    newlyDeletedLiveChatIds: goneLiveChats.ids.difference(
      context.deletedLiveChatIds,
    ),
    newCommentIds: comments.keys.toSet().difference(baseCommentIds),
    newLiveChatIds: liveChats.keys.toSet().difference(baseLiveChatIds),
    commentCheckSkipped: goneComments.skipped,
    liveChatCheckSkipped: goneLiveChats.skipped,
    history: planHistoryImport(
      saved: context.merge ? savedHistory : null,
      picked: [for (final e in exports) ?e.history],
    ),
    accountAssumed: accountAssumed,
    baseTakeoutId: context.activeTakeoutId,
  );
}

/// Orders sources by the time of their data. On a tie the export is the
/// newer copy of the same data.
int _compareSnapshots(DateTime aTime, _Source a, DateTime bTime, _Source b) {
  final byTime = aTime.compareTo(bTime);
  if (byTime != 0) return byTime;
  return (a.isSaved ? 0 : 1) - (b.isSaved ? 0 : 1);
}

/// One source of takeout data: the saved data or one picked export.
class _Source {
  final TakeoutData data;

  /// When this data was exported from YouTube.
  final DateTime snapshot;
  final bool isSaved;

  /// Whether nothing in it names a channel of its account: a zip part with
  /// only subscriptions or history, say.
  bool get unidentified => channels.isEmpty;

  /// The channels it has: listed in its channel.csv, or writing its items.
  Set<String> get channels => {
    ...data.ownChannels.keys,
    ...data.authorChannelIds,
  };
  final _Kind comments;
  final _Kind liveChats;

  factory _Source.saved(TakeoutData data) {
    final snapshot = data.latestExportAt ?? data.newestItemAt ?? _epoch;
    return _Source._(
      data: data,
      snapshot: snapshot,
      isSaved: true,
      comments: _Kind.saved(
        ids: {for (final c in data.comments) c.commentId},
        snapshot: data.commentsSnapshot,
        fallbackTime: snapshot,
      ),
      liveChats: _Kind.saved(
        ids: {for (final l in data.liveChats) l.liveChatId},
        snapshot: data.liveChatsSnapshot,
        fallbackTime: snapshot,
      ),
    );
  }

  factory _Source.export(TakeoutExport export) {
    final data = export.data;
    final snapshot = export.exportedAt ?? data.newestItemAt ?? _epoch;
    return _Source._(
      data: data,
      snapshot: snapshot,
      isSaved: false,
      comments: _Kind(
        present: export.commentPages.isNotEmpty,
        ids: {for (final c in data.comments) c.commentId},
        time: snapshot,
        untrusted: _untrusted(export.commentPages, data.skippedCommentRows),
      ),
      liveChats: _Kind(
        present: export.liveChatPages.isNotEmpty,
        ids: {for (final l in data.liveChats) l.liveChatId},
        time: snapshot,
        untrusted: _untrusted(export.liveChatPages, data.skippedLiveChatRows),
      ),
    );
  }

  _Source._({
    required this.data,
    required this.snapshot,
    required this.isSaved,
    required this.comments,
    required this.liveChats,
  });
}

/// One source's comments or live chats.
class _Kind {
  /// Whether the source has this kind at all, even with no rows.
  final bool present;
  final Set<String> ids;

  /// When this kind was exported. Saved data remembers it per kind, since a
  /// newer takeout may not have had every kind.
  final DateTime time;

  /// Set when the source may be missing items of this kind.
  final DeletionCheckSkipReason? untrusted;

  const _Kind({
    required this.present,
    required this.ids,
    required this.time,
    this.untrusted,
  });

  /// Saved data is only trusted when the takeout it last came from was
  /// complete for this kind.
  _Kind.saved({
    required this.ids,
    required KindSnapshot? snapshot,
    required DateTime fallbackTime,
  }) : present = ids.isNotEmpty,
       time = snapshot?.exportedAt ?? fallbackTime,
       untrusted = snapshot?.complete == true
           ? null
           : DeletionCheckSkipReason.savedDataUnverified;

  KindSnapshot get snapshot =>
      KindSnapshot(exportedAt: time, complete: untrusted == null);
}

/// The newest source's details for one kind.
typedef _Newest = ({_Kind kind, KindSnapshot snapshot, Set<String> channels});

_Newest? _newestWith(List<_Source> sources, _Kind Function(_Source) kindOf) {
  _Source? newest;
  for (final source in sources) {
    if (!kindOf(source).present) continue;
    if (newest == null ||
        _compareSnapshots(
              kindOf(source).time,
              source,
              kindOf(newest).time,
              newest,
            ) >
            0) {
      newest = source;
    }
  }
  if (newest == null) return null;
  final kind = kindOf(newest);
  return (kind: kind, snapshot: kind.snapshot, channels: newest.channels);
}

/// Works out which saved takeout the exports go into. They must all be from
/// one Google account: the same main channel when both name one, otherwise
/// sharing a channel. They go into the saved takeout they share a channel
/// with, else a new one saved under their main channel (or the channel that
/// wrote most). Throws when they share channels with two saved takeouts, or
/// when merging them into a takeout other than the one selected. Replacing
/// with another takeout is allowed.
///
/// Takeouts are split into zips of whatever they hold, and some parts name
/// no channel (only subscriptions or history, say). Those go with the other
/// exports; with nothing else, into the takeout selected, flagged
/// [TakeoutImportPlan.accountAssumed] for the review to name it.
({String id, bool accountAssumed}) _resolveTakeout(
  List<_Source> picked,
  TakeoutImportContext context,
) {
  final exports = [
    for (final export in picked)
      if (!export.unidentified) export,
  ];
  if (exports.isEmpty) {
    final selected = context.activeTakeoutId;
    if (selected == null) {
      throw const TakeoutImportException(
        "Nothing in the selected takeout says which YouTube account it's "
        'from: it has no comments, live chats or channel list. Import one of '
        "the account's takeouts with those first, then add this one to it.",
      );
    }
    return (id: selected, accountAssumed: true);
  }
  final titles = {
    for (final data in [
      for (final export in exports) export.data,
      ?context.saved,
    ])
      for (final own in data.ownChannels.values) own.channelId: ?own.title,
  };
  Set<String>? found;
  String? main;
  for (final export in exports) {
    final channels = export.channels;
    for (final id in channels) {
      if (!isChannelId(id)) {
        throw TakeoutImportException(
          'The selected takeout has an unexpected channel ID ("$id").',
        );
      }
    }
    final exportMain = export.data.listedMainChannelId;
    if (found == null) {
      found = {...channels};
      main = exportMain;
      continue;
    }
    final sameAccount = main != null && exportMain != null
        ? main == exportMain
        : found.intersection(channels).isNotEmpty;
    if (!sameAccount) {
      throw TakeoutAccountMismatchException(
        'The selected takeouts are from different YouTube accounts.',
        expectedChannelIds: found,
        foundChannelIds: channels,
        titlesById: titles,
      );
    }
    found.addAll(channels);
    main ??= exportMain;
  }
  // planTakeoutImport refuses an empty list.
  final channels = found!;

  // Data saved before takeouts were kept per account can mix channels; it
  // belongs to the one that wrote most of it.
  final saved = context.saved;
  final activeId = context.activeTakeoutId ?? saved?.mostCommonAuthor;
  final savedSets = {
    ...context.savedChannelSets,
    if (activeId != null &&
        saved != null &&
        !context.savedChannelSets.containsKey(activeId))
      activeId: {activeId, ..._Source.saved(saved).channels},
  };

  final matches = [
    for (final MapEntry(key: id, value: set) in savedSets.entries)
      if (set.intersection(channels).isNotEmpty) id,
  ];
  if (matches.length > 1) {
    throw TakeoutAccountMismatchException(
      'This takeout has channels from more than one saved takeout.',
      expectedChannelIds: {for (final id in matches) ...savedSets[id]!},
      foundChannelIds: channels,
      titlesById: titles,
    );
  }
  final takeoutId =
      matches.singleOrNull ??
      main ??
      mostCommonAuthorIn([for (final e in exports) e.data]) ??
      channels.first;

  if (!context.merge || activeId == null || takeoutId == activeId) {
    return (id: takeoutId, accountAssumed: false);
  }
  throw TakeoutAccountMismatchException(
    'This takeout is from a different YouTube account than your current '
    'data.',
    expectedChannelIds: savedSets[activeId] ?? {activeId},
    foundChannelIds: channels,
    titlesById: titles,
  );
}

/// IDs in [createdAtById] that the [newest] source of their kind no longer
/// has, or why that source can't be trusted to tell.
({Set<String> ids, DeletionCheckSkipReason? skipped}) _findGone(
  _Newest? newest,
  Map<String, DateTime> createdAtById,
) {
  if (newest == null) return (ids: {}, skipped: null);
  final kind = newest.kind;
  if (kind.untrusted != null) return (ids: {}, skipped: kind.untrusted);

  return (
    ids: {
      for (final MapEntry(key: id, value: createdAt) in createdAtById.entries)
        if (!kind.ids.contains(id) && !createdAt.isAfter(kind.time)) id,
    },
    skipped: null,
  );
}

DeletionCheckSkipReason? _untrusted(CsvPages pages, int skippedRows) {
  if (pages.isNotEmpty && !_isComplete(pages)) {
    return DeletionCheckSkipReason.incompleteFiles;
  }
  return skippedRows > 0 ? DeletionCheckSkipReason.unparsedRows : null;
}

/// How many rows Takeout puts in each numbered CSV file.
const _takeoutPageSize = 200;

/// Takeout splits rows into numbered files of the same size, so only the
/// last file is short. A missing number, or a last file that's as full as
/// the others, means files may not have been picked.
bool _isComplete(CsvPages pages) {
  final rowsByPage = <int, int>{};
  for (final p in pages) {
    // The same file number with different contents.
    if (rowsByPage.containsKey(p.page)) return false;
    rowsByPage[p.page] = p.rows;
  }
  final lastPage = rowsByPage.length - 1;
  if (rowsByPage.keys.any((n) => n > lastPage)) return false;
  // A lone file as full as Takeout makes them may have more after it.
  if (lastPage == 0) return rowsByPage[0]! < _takeoutPageSize;

  final pageSize = rowsByPage[0]!;
  for (var n = 1; n < lastPage; n++) {
    if (rowsByPage[n] != pageSize) return false;
  }
  return rowsByPage[lastPage]! < pageSize;
}

int _sum(List<_Source> sources, int Function(_Source) count) =>
    sources.fold(0, (sum, s) => sum + count(s));
