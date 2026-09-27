import 'dart:typed_data';

import '../domain/loaded_takeout.dart';
import '../domain/own_channel.dart';
import '../domain/takeout_channel.dart';
import '../domain/takeout_data.dart';
import 'csv_parser.dart';
import 'takeout_files.dart';
import 'takeout_meta_codec.dart';
import 'takeout_repository.dart';

/// Whether [path] is one of the small saved files a takeout's summary is
/// read from.
bool isTakeoutSummaryPath(String path) =>
    TakeoutFile.classify(path)?.forSummary ?? false;

/// Reads a [TakeoutSummary] from a saved takeout's summary files (see
/// [isTakeoutSummaryPath]).
TakeoutSummary parseTakeoutSummary(
  String takeoutId,
  Map<String, Uint8List> summaryFiles,
) {
  final parser = CsvParser();
  final own = <String, OwnChannel>{};
  final vanityNames = <String, String>{};
  Map<String, ItemCounts>? counts;
  DateTime? latestExportAt;
  for (final MapEntry(key: path, value: bytes) in summaryFiles.entries) {
    switch (TakeoutFile.classify(path)) {
      case TakeoutFile.channelCounts:
        counts = decodeChannelCounts(bytes);
      case TakeoutFile.meta:
        latestExportAt = decodeTakeoutMeta(bytes).latestExportAt;
      case TakeoutFile.channels:
        for (final c in parser.parseChannelsCsv(bytes)) {
          own[c.channelId] = c;
        }
      case TakeoutFile.channelUrlConfigs:
        vanityNames.addAll(parser.parseChannelUrlConfigsCsv(bytes));
      case TakeoutFile.comments ||
          TakeoutFile.liveChats ||
          TakeoutFile.subscriptions ||
          null:
        break;
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

/// Every saved takeout's summary, from its summary files. [loaded]'s comes
/// from its data instead.
Future<List<TakeoutSummary>> loadTakeoutSummaries(
  TakeoutRepository repository, {
  LoadedTakeout? loaded,
}) async => [
  for (final id in await repository.listAccountIds())
    if (loaded != null && loaded.id == id)
      TakeoutSummary(
        id: id,
        channels: takeoutChannelsOf(loaded.data, takeoutId: id),
        latestExportAt: loaded.data.latestExportAt,
        countsKnown: true,
      )
    else
      parseTakeoutSummary(
        id,
        await repository.loadCsvs(id, only: isTakeoutSummaryPath) ?? const {},
      ),
];
