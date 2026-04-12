import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/comment.dart';
import '../models/live_chat.dart';
import '../models/subscription.dart';
import '../models/takeout_data.dart';
import 'csv_parser_service.dart';
import 'zip_extraction_service.dart';

/// Orchestrates the full takeout import pipeline:
/// file picker → read bytes → extract zips → parse CSVs → return TakeoutData.
class TakeoutImportService {
  /// Opens a file picker for the user to select one or more takeout zip files,
  /// then parses them and returns the aggregated [TakeoutData].
  ///
  /// Returns null if the user cancels the file picker.
  Future<TakeoutData?> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final zipBytesList = <Uint8List>[];
    for (final file in result.files) {
      if (file.path != null) {
        // Desktop/mobile: read from file path
        zipBytesList.add(await File(file.path!).readAsBytes());
      } else if (file.bytes != null) {
        // Web: bytes are available directly
        zipBytesList.add(file.bytes!);
      }
    }

    if (zipBytesList.isEmpty) return null;

    // Run heavy parsing work in an isolate to avoid UI jank
    return Isolate.run(() => _parseInIsolate(zipBytesList));
  }

  /// Imports from pre-loaded zip bytes (useful for testing or programmatic use).
  Future<TakeoutData> importFromBytes(List<Uint8List> zipBytesList) async {
    return Isolate.run(() => _parseInIsolate(zipBytesList));
  }

  TakeoutData _parseInIsolate(List<Uint8List> zipBytesList) {
    final zipService = ZipExtractionService();
    final csvParser = CsvParserService();

    final extractedFiles = zipService.extractRelevantFiles(zipBytesList);

    final comments = <Comment>[];
    final liveChats = <LiveChat>[];
    final subscriptions = <Subscription>[];

    for (final entry in extractedFiles.entries) {
      final path = entry.key.toLowerCase();
      final bytes = entry.value;

      if (path.contains('comments/comments') && path.endsWith('.csv')) {
        comments.addAll(csvParser.parseCommentsCsv(bytes));
      } else if (path.contains('live chats/live chats') &&
          path.endsWith('.csv')) {
        liveChats.addAll(csvParser.parseLiveChatsCsv(bytes));
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
    );
  }
}
