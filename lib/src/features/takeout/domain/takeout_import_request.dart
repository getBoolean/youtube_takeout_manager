import 'dart:typed_data';

import 'takeout_data.dart';

/// A takeout zip the user picked, read into memory.
typedef PickedZip = ({String name, Uint8List bytes});

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
});
