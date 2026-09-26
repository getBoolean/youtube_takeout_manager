import 'dart:typed_data';

import '../domain/own_channel.dart';
import '../domain/takeout_channel.dart';
import 'csv_parser_service.dart';
import 'takeout_csv_encoder.dart';

/// Reads a [TakeoutSummary] from a saved takeout's summary files (see
/// `isTakeoutSummaryPath`).
TakeoutSummary parseTakeoutSummary(
  String takeoutId,
  Map<String, Uint8List> summaryFiles,
) {
  final parser = CsvParserService();
  final own = <String, OwnChannel>{};
  final vanityNames = <String, String>{};
  Map<String, ({int comments, int liveChats})>? counts;
  DateTime? latestExportAt;
  for (final MapEntry(key: path, value: bytes) in summaryFiles.entries) {
    final lower = path.toLowerCase();
    if (lower.endsWith(takeoutChannelsMetaPath)) {
      counts = parser.parseChannelCountsCsv(bytes);
    } else if (lower.endsWith(takeoutMetaPath)) {
      latestExportAt = parser.parseMetaCsv(bytes).latestExportAt;
    } else if (lower.endsWith(channelsCsvPath)) {
      for (final c in parser.parseChannelsCsv(bytes)) {
        own[c.channelId] = c;
      }
    } else if (lower.endsWith(channelUrlConfigsCsvPath)) {
      vanityNames.addAll(parser.parseChannelUrlConfigsCsv(bytes));
    }
  }
  return TakeoutSummary(
    id: takeoutId,
    channels: takeoutChannelsFrom(takeoutId, {
      for (final MapEntry(key: id, value: c) in own.entries)
        id: c.copyWith(vanityName: vanityNames[id]),
    }, counts ?? const {}),
    latestExportAt: latestExportAt,
    countsKnown: counts != null,
  );
}
