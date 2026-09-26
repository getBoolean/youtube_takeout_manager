import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../domain/channel_id.dart';
import '../domain/own_channel.dart';
import '../domain/subscription.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_import_plan.dart';
import 'takeout_csv_encoder.dart';
import 'takeout_import_service.dart';
import 'zip_extraction_service.dart';

typedef PickedZip = ({String name, Uint8List bytes});

typedef TakeoutImportRequest = ({
  List<PickedZip> zips,
  TakeoutData? saved,

  /// Whether to add the zips to [saved] instead of replacing it.
  bool merge,

  Set<String> deletedCommentIds,
  Set<String> deletedLiveChatIds,
});

/// The export time Google puts in takeout zip names, e.g.
/// `takeout-20260412T074021Z-3-001.zip`.
final _exportTime = RegExp(r'takeout-(\d{8}t\d{6}z)', caseSensitive: false);

final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// Top-level function for `compute` — reads the picked zips, merges them
/// with the saved data and works out which items are no longer on YouTube.
///
/// For each kind, the account's items missing from the newest source of
/// that kind are gone, unless they were created after that source was
/// exported. Throws a [TakeoutImportException] when the zips can't be
/// imported safely.
TakeoutImportPlan planTakeoutImport(TakeoutImportRequest request) {
  final saved = request.saved;
  final base = request.merge ? saved : null;
  final exports = _readExports(request.zips);
  final (:accountId, :differentAccount) = _checkAccount(
    exports,
    saved: saved,
    merge: request.merge,
  );

  final sources = [if (base != null) _Source.saved(base), ...exports]
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
  // Only the account's own items can be found gone, even if the saved data
  // also holds another channel's.
  final goneComments = _findGone(newestComments, {
    for (final c in comments.values)
      if (c.channelId == accountId) c.commentId: c.createdAt,
  });
  final goneLiveChats = _findGone(newestLiveChats, {
    for (final l in liveChats.values)
      if (l.channelId == accountId) l.liveChatId: l.createdAt,
  });

  final mergedData = TakeoutData(
    comments: comments.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    liveChats: liveChats.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    subscriptionsByChannelId: subscriptions,
    skippedCommentRows: _sum(exports, (e) => e.data.skippedCommentRows),
    skippedLiveChatRows: _sum(exports, (e) => e.data.skippedLiveChatRows),
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
    csvFiles: encodeTakeoutCsvs(mergedData),
    goneCommentIds: goneComments.ids,
    goneLiveChatIds: goneLiveChats.ids,
    newlyDeletedCommentCount: goneComments.ids
        .difference(request.deletedCommentIds)
        .length,
    newlyDeletedLiveChatCount: goneLiveChats.ids
        .difference(request.deletedLiveChatIds)
        .length,
    newCommentCount: comments.keys
        .where((id) => !baseCommentIds.contains(id))
        .length,
    newLiveChatCount: liveChats.keys
        .where((id) => !baseLiveChatIds.contains(id))
        .length,
    commentCheckSkipped: goneComments.skipped,
    liveChatCheckSkipped: goneLiveChats.skipped,
    differentAccount: differentAccount,
  );
}

/// The channel that wrote most of [data]'s comments and live chats, or null
/// if it has none.
String? mostCommonAuthorChannelId(TakeoutData data) {
  final counts = <String, int>{};
  for (final id in [
    for (final c in data.comments) c.channelId,
    for (final l in data.liveChats) l.channelId,
  ]) {
    if (id.isNotEmpty) counts[id] = (counts[id] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
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
  final _Kind comments;
  final _Kind liveChats;

  factory _Source.saved(TakeoutData data) {
    final snapshot = data.latestExportAt ?? _newestItem(data) ?? _epoch;
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

  factory _Source.export({
    required DateTime? exportedAt,
    required ({TakeoutData data, CsvPages commentPages, CsvPages liveChatPages})
    parsed,
  }) {
    final data = parsed.data;
    final snapshot = exportedAt ?? _newestItem(data) ?? _epoch;
    return _Source._(
      data: data,
      snapshot: snapshot,
      isSaved: false,
      comments: _Kind(
        present: parsed.commentPages.isNotEmpty,
        ids: {for (final c in data.comments) c.commentId},
        time: snapshot,
        untrusted: _untrusted(parsed.commentPages, data.skippedCommentRows),
      ),
      liveChats: _Kind(
        present: parsed.liveChatPages.isNotEmpty,
        ids: {for (final l in data.liveChats) l.liveChatId},
        time: snapshot,
        untrusted: _untrusted(parsed.liveChatPages, data.skippedLiveChatRows),
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
typedef _Newest = ({_Kind kind, KindSnapshot snapshot});

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
  return (kind: kind, snapshot: kind.snapshot);
}

List<_Source> _readExports(List<PickedZip> zips) {
  final zipsByExport = <DateTime?, List<PickedZip>>{};
  for (final zip in zips) {
    final time = _exportTime.firstMatch(zip.name)?.group(1)?.toUpperCase();
    zipsByExport
        .putIfAbsent(time != null ? DateTime.parse(time) : null, () => [])
        .add(zip);
  }

  if (zipsByExport.length > 1 && zipsByExport.containsKey(null)) {
    final names = zipsByExport[null]!.map((z) => '"${z.name}"').join(', ');
    throw TakeoutImportException(
      "Can't tell which takeout $names belongs to. Keep the original "
      'takeout-… file names, or add one takeout at a time.',
    );
  }

  final exports = <_Source>[];
  for (final MapEntry(key: exportedAt, value: zips) in zipsByExport.entries) {
    final files = ZipExtractionService().extractRelevantFiles([
      for (final zip in zips) zip.bytes,
    ]);
    if (files.isEmpty) continue;
    exports.add(
      _Source.export(exportedAt: exportedAt, parsed: parseTakeoutFiles(files)),
    );
  }
  if (exports.isEmpty) {
    throw const TakeoutImportException(
      'No comments, live chats or subscriptions were found in the selected '
      'files.',
    );
  }
  return exports;
}

/// Works out the account the exports belong to: the one author channel they
/// all share. Throws when there isn't exactly one, or when adding, when it
/// isn't the saved data's channel. When
/// replacing, a different channel than the saved data's is allowed and
/// returned as [ChannelMismatch] instead.
({String accountId, ChannelMismatch? differentAccount}) _checkAccount(
  List<_Source> exports, {
  required TakeoutData? saved,
  required bool merge,
}) {
  String? accountId;
  for (final export in exports) {
    final found = _authorChannelIds(export.data);
    if (found.isEmpty) {
      throw const TakeoutImportException(
        'The selected takeout has no comments or live chats, so its YouTube '
        "account can't be determined.",
      );
    }
    if (found.length > 1) {
      throw TakeoutImportException(
        'The selected takeout has comments from more than one YouTube '
        "channel (${found.join(', ')}), so its account can't be determined.",
      );
    }
    if (!isChannelId(found.single)) {
      throw TakeoutImportException(
        'The selected takeout has an unexpected channel ID '
        '("${found.single}").',
      );
    }
    if (accountId == null) {
      accountId = found.single;
    } else if (found.single != accountId) {
      throw TakeoutAccountMismatchException(
        'The selected takeouts are from different YouTube accounts.',
        expectedChannelIds: {accountId},
        foundChannelIds: found,
      );
    }
  }
  // _readExports never returns an empty list.
  final id = accountId!;

  // Data saved before takeouts were kept per account can mix channels; it
  // belongs to the one that wrote most of it.
  final savedId = saved != null ? mostCommonAuthorChannelId(saved) : null;
  if (savedId == null || savedId == id) {
    return (accountId: id, differentAccount: null);
  }
  if (merge) {
    throw TakeoutAccountMismatchException(
      'This takeout is from a different YouTube account than your current '
      'data.',
      expectedChannelIds: {savedId},
      foundChannelIds: {id},
    );
  }
  return (
    accountId: id,
    differentAccount: ChannelMismatch(
      expectedChannelIds: {savedId},
      foundChannelIds: {id},
    ),
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

Set<String> _authorChannelIds(TakeoutData data) => {
  for (final c in data.comments) c.channelId,
  for (final l in data.liveChats) l.channelId,
}..remove('');

DateTime? _newestItem(TakeoutData data) {
  DateTime? newest;
  for (final t in [
    for (final c in data.comments) c.createdAt,
    for (final l in data.liveChats) l.createdAt,
  ]) {
    if (newest == null || t.isAfter(newest)) newest = t;
  }
  return newest;
}

int _sum(List<_Source> sources, int Function(_Source) count) =>
    sources.fold(0, (sum, s) => sum + count(s));
