import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/comment.dart';
import '../models/live_chat.dart';
import '../models/subscription.dart';
import '../models/takeout_data.dart';
import 'csv_parser_service.dart';
import 'zip_extraction_service.dart';

/// Top-level function for [compute] — extracts zips and returns the
/// extracted CSV file map (path → bytes).
Map<String, Uint8List> _extractCsvFiles(List<Uint8List> zipBytesList) {
  return ZipExtractionService().extractRelevantFiles(zipBytesList);
}

/// Top-level function for [compute] — parses a map of CSV file paths to
/// bytes into [TakeoutData].
TakeoutData parseCsvFiles(Map<String, Uint8List> extractedFiles) {
  final csvParser = CsvParserService();

  final comments = <Comment>[];
  final liveChats = <LiveChat>[];
  final subscriptions = <Subscription>[];
  var rawCommentLines = 0;
  var rawLiveChatLines = 0;
  var parsedCommentRows = 0;
  var parsedLiveChatRows = 0;
  var skippedCommentRows = 0;
  var skippedLiveChatRows = 0;

  for (final entry in extractedFiles.entries) {
    final path = entry.key.toLowerCase();
    final bytes = entry.value;

    if (path.contains('comments/comments') && path.endsWith('.csv')) {
      final result = csvParser.parseCommentsCsv(bytes);
      comments.addAll(result.items);
      rawCommentLines += result.rawLineCount;
      parsedCommentRows += result.parsedRowCount;
      skippedCommentRows += result.skippedRowCount;
    } else if (path.contains('live chats/live chats') &&
        path.endsWith('.csv')) {
      final result = csvParser.parseLiveChatsCsv(bytes);
      liveChats.addAll(result.items);
      rawLiveChatLines += result.rawLineCount;
      parsedLiveChatRows += result.parsedRowCount;
      skippedLiveChatRows += result.skippedRowCount;
    } else if (path.contains('subscriptions/subscriptions') &&
        path.endsWith('.csv')) {
      subscriptions.addAll(csvParser.parseSubscriptionsCsv(bytes));
    }
  }

  final subscriptionsByChannelId = <String, Subscription>{};
  for (final sub in subscriptions) {
    subscriptionsByChannelId[sub.channelId] = sub;
  }

  return TakeoutData(
    comments: comments,
    liveChats: liveChats,
    subscriptionsByChannelId: subscriptionsByChannelId,
    rawCommentLines: rawCommentLines,
    rawLiveChatLines: rawLiveChatLines,
    parsedCommentRows: parsedCommentRows,
    parsedLiveChatRows: parsedLiveChatRows,
    skippedCommentRows: skippedCommentRows,
    skippedLiveChatRows: skippedLiveChatRows,
  );
}

/// Orchestrates the full takeout import pipeline:
/// file picker → read bytes → extract zips → parse CSVs → return TakeoutData.
class TakeoutImportService {
  /// Opens a file picker for the user to select one or more takeout zip files,
  /// then extracts the relevant CSV files and returns them as a map of
  /// path → bytes, along with the parsed [TakeoutData].
  ///
  /// Returns null if the user cancels the file picker.
  Future<({Map<String, Uint8List> csvFiles, TakeoutData data})?>
  pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final zipBytesList = <Uint8List>[];
    for (final file in result.files) {
      if (file.bytes != null) {
        zipBytesList.add(file.bytes!);
      }
    }

    if (zipBytesList.isEmpty) return null;

    // Extract CSVs in isolate (heavy zip decoding).
    final csvFiles = await compute(_extractCsvFiles, zipBytesList);

    // Parse the extracted CSVs in isolate.
    final data = await compute(parseCsvFiles, csvFiles);

    return (csvFiles: csvFiles, data: data);
  }

  /// Extracts and parses pre-loaded zip bytes, returning both the raw CSV
  /// file map (for persistence) and the parsed data.
  Future<({Map<String, Uint8List> csvFiles, TakeoutData data})>
  importFromPickedBytes(List<Uint8List> zipBytesList) async {
    final csvFiles = await compute(_extractCsvFiles, zipBytesList);
    final data = await compute(parseCsvFiles, csvFiles);
    return (csvFiles: csvFiles, data: data);
  }
}
