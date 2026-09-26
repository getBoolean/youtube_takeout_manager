import 'dart:typed_data';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import '../domain/own_channel.dart';
import '../domain/subscription.dart';
import '../domain/takeout_data.dart';
import 'csv_parser_service.dart';
import 'takeout_csv_encoder.dart';

/// Row counts of one kind's numbered CSV files, e.g. `comments(3).csv` is
/// page 3 and `comments.csv` is page 0. A set, so the same file picked twice
/// counts once.
typedef CsvPages = Set<({int page, int rows})>;

final _pageNumber = RegExp(r'\((\d+)\)\.csv$');

/// Top-level function for `compute` — parses a map of CSV file paths to
/// bytes into [TakeoutData].
TakeoutData parseCsvFiles(Map<String, Uint8List> extractedFiles) =>
    parseTakeoutFiles(extractedFiles).data;

/// Parses takeout CSV files like [parseCsvFiles], also returning how the
/// comments and live chats were paged across files.
({TakeoutData data, CsvPages commentPages, CsvPages liveChatPages})
parseTakeoutFiles(Map<String, Uint8List> extractedFiles) {
  final csvParser = CsvParserService();

  final comments = <Comment>[];
  final liveChats = <LiveChat>[];
  final subscriptions = <Subscription>[];
  final ownChannels = <OwnChannel>[];
  final vanityNames = <String, String>{};
  final CsvPages commentPages = {};
  final CsvPages liveChatPages = {};
  var skippedCommentRows = 0;
  var skippedLiveChatRows = 0;
  DateTime? latestExportAt;
  KindSnapshot? commentsSnapshot;
  KindSnapshot? liveChatsSnapshot;

  int page(String path) =>
      int.parse(_pageNumber.firstMatch(path)?.group(1) ?? '0');

  for (final entry in extractedFiles.entries) {
    final path = entry.key.toLowerCase();
    final bytes = entry.value;

    if (path.endsWith(takeoutMetaPath)) {
      final meta = csvParser.parseMetaCsv(bytes);
      latestExportAt = meta.latestExportAt;
      commentsSnapshot = meta.commentsSnapshot;
      liveChatsSnapshot = meta.liveChatsSnapshot;
      skippedCommentRows += meta.skippedCommentRows;
      skippedLiveChatRows += meta.skippedLiveChatRows;
    } else if (path.contains('comments/comments') && path.endsWith('.csv')) {
      final result = csvParser.parseCommentsCsv(bytes);
      comments.addAll(result.items);
      commentPages.add((page: page(path), rows: result.parsedRowCount));
      skippedCommentRows += result.skippedRowCount;
    } else if (path.contains('live chats/live chats') &&
        path.endsWith('.csv')) {
      final result = csvParser.parseLiveChatsCsv(bytes);
      liveChats.addAll(result.items);
      liveChatPages.add((page: page(path), rows: result.parsedRowCount));
      skippedLiveChatRows += result.skippedRowCount;
    } else if (path.contains('subscriptions/subscriptions') &&
        path.endsWith('.csv')) {
      subscriptions.addAll(csvParser.parseSubscriptionsCsv(bytes));
    } else if (path.endsWith(channelsCsvPath)) {
      ownChannels.addAll(csvParser.parseChannelsCsv(bytes));
    } else if (path.endsWith(channelUrlConfigsCsvPath)) {
      vanityNames.addAll(csvParser.parseChannelUrlConfigsCsv(bytes));
    }
  }

  final subscriptionsByChannelId = <String, Subscription>{};
  for (final sub in subscriptions) {
    subscriptionsByChannelId[sub.channelId] = sub;
  }
  final ownChannelsById = <String, OwnChannel>{
    for (final channel in ownChannels)
      channel.channelId: channel.copyWith(
        vanityName: vanityNames[channel.channelId],
      ),
  };

  return (
    data: TakeoutData(
      comments: comments,
      liveChats: liveChats,
      subscriptionsByChannelId: subscriptionsByChannelId,
      skippedCommentRows: skippedCommentRows,
      skippedLiveChatRows: skippedLiveChatRows,
      latestExportAt: latestExportAt,
      commentsSnapshot: commentsSnapshot,
      liveChatsSnapshot: liveChatsSnapshot,
      ownChannels: ownChannelsById,
    ),
    commentPages: commentPages,
    liveChatPages: liveChatPages,
  );
}
