import 'dart:typed_data';

import 'takeout_data.dart';

/// A takeout zip the user picked.
sealed class PickedZip {
  /// Its file name, which tells which export it's part of.
  final String name;

  const PickedZip._(this.name);

  /// A zip read from [path] when it's imported. Takeouts can hold tens of
  /// gigabytes of videos, so only the files the import needs are read.
  const factory PickedZip.file(String name, String path) = PickedZipFile;

  /// A zip already read into memory, as a browser hands it over.
  const factory PickedZip.bytes(String name, Uint8List bytes) = PickedZipBytes;
}

final class PickedZipFile extends PickedZip {
  final String path;

  const PickedZipFile(super.name, this.path) : super._();
}

final class PickedZipBytes extends PickedZip {
  final Uint8List bytes;

  const PickedZipBytes(super.name, this.bytes) : super._();
}

/// What picked takeouts are imported against: the saved data and what's
/// known about the other saved takeouts.
typedef TakeoutImportContext = ({
  TakeoutData? saved,

  /// Whether to add the takeouts to [saved] instead of replacing it.
  bool merge,

  Set<String> deletedCommentIds,
  Set<String> deletedLiveChatIds,

  /// Each saved takeout's channels, by the ID it's saved under. An import
  /// goes into the one it shares a channel with.
  Map<String, Set<String>> savedChannelSets,

  /// The takeout selected when the import started.
  String? activeTakeoutId,
});

/// Picked zips to import, and what they're imported against.
typedef TakeoutImportRequest = ({
  List<PickedZip> zips,
  TakeoutImportContext context,

  /// The saved takeout's history files, when merging: parsed only if the
  /// picked zips have history to merge with them, else saved again as they
  /// are.
  Map<String, Uint8List> savedHistoryFiles,
});
