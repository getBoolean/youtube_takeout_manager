import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_files.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_html_parser.dart';
import 'package:youtube_takeout_manager/src/features/history/data/history_json_parser.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/search_entry.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/takeout_history.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watch_entry.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../domain/own_channel.dart';
import '../domain/subscription.dart';
import '../domain/takeout_data.dart';
import '../domain/takeout_export.dart';
import 'csv_parser.dart';
import 'takeout_files.dart';
import 'takeout_meta_codec.dart';

final _pageNumber = RegExp(r'\((\d+)\)\.csv$');

/// Top-level function for `compute` — parses a map of CSV file paths to
/// bytes into [TakeoutData].
TakeoutData parseCsvFiles(Map<String, Uint8List> files) =>
    parseTakeoutFiles(files).data;

/// Parses takeout CSV files like [parseCsvFiles], also keeping how the
/// comments and live chats were paged across files, as one export made at
/// [exportedAt].
TakeoutExport parseTakeoutFiles(
  Map<String, Uint8List> files, {
  DateTime? exportedAt,
}) {
  final csvParser = CsvParser();

  final comments = <Comment>[];
  final liveChats = <LiveChat>[];
  final subscriptions = <Subscription>[];
  final ownChannels = <OwnChannel>[];
  final vanityNames = <String, String>{};
  final CsvPages commentPages = {};
  final CsvPages liveChatPages = {};
  var skippedCommentRows = 0;
  var skippedLiveChatRows = 0;
  TakeoutMeta? meta;
  HistoryFileRead<WatchEntry>? watches;
  HistoryFileRead<SearchEntry>? searches;

  int page(String path) =>
      int.parse(_pageNumber.firstMatch(path.toLowerCase())?.group(1) ?? '0');

  for (final MapEntry(key: path, value: bytes) in files.entries) {
    switch (TakeoutFile.classify(path)) {
      case TakeoutFile.meta:
        meta = decodeTakeoutMeta(bytes);
        skippedCommentRows += meta.skippedCommentRows;
        skippedLiveChatRows += meta.skippedLiveChatRows;
      case TakeoutFile.comments:
        final result = csvParser.parseCommentsCsv(bytes);
        comments.addAll(result.items);
        commentPages.add((page: page(path), rows: result.parsedRowCount));
        skippedCommentRows += result.skippedRowCount;
      case TakeoutFile.liveChats:
        final result = csvParser.parseLiveChatsCsv(bytes);
        liveChats.addAll(result.items);
        liveChatPages.add((page: page(path), rows: result.parsedRowCount));
        skippedLiveChatRows += result.skippedRowCount;
      case TakeoutFile.subscriptions:
        subscriptions.addAll(csvParser.parseSubscriptionsCsv(bytes));
      case TakeoutFile.channels:
        ownChannels.addAll(csvParser.parseChannelsCsv(bytes));
      case TakeoutFile.channelUrlConfigs:
        vanityNames.addAll(csvParser.parseChannelUrlConfigsCsv(bytes));
      // Only a saved takeout's summary is read from it.
      case TakeoutFile.channelCounts:
        break;
      case null:
        // A zip picked twice has the same history twice; one is enough.
        switch (HistoryFile.classify(path)) {
          case HistoryFile.watches when watches == null:
            watches = _isJson(path)
                ? parseWatchHistoryJson(bytes)
                : parseWatchHistoryHtml(bytes);
          case HistoryFile.searches when searches == null:
            searches = _isJson(path)
                ? parseSearchHistoryJson(bytes)
                : parseSearchHistoryHtml(bytes);
          // A saved takeout's history is loaded on its own.
          case _:
            break;
        }
    }
  }

  return TakeoutExport(
    exportedAt: exportedAt,
    data: TakeoutData(
      comments: comments,
      liveChats: liveChats,
      subscriptionsByChannelId: {
        for (final sub in subscriptions) sub.channelId: sub,
      },
      skippedCommentRows: skippedCommentRows,
      skippedLiveChatRows: skippedLiveChatRows,
      latestExportAt: meta?.latestExportAt,
      commentsSnapshot: meta?.commentsSnapshot,
      liveChatsSnapshot: meta?.liveChatsSnapshot,
      ownChannels: {
        for (final channel in ownChannels)
          channel.channelId: channel.copyWith(
            vanityName: vanityNames[channel.channelId],
          ),
      },
    ),
    commentPages: commentPages,
    liveChatPages: liveChatPages,
    history: watches == null && searches == null
        ? null
        : ExportHistory(
            exportedAt: exportedAt,
            watches: watches,
            searches: searches,
          ),
  );
}

bool _isJson(String path) => path.toLowerCase().endsWith('.json');
