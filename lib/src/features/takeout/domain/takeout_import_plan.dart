import 'dart:typed_data';

import 'takeout_channel.dart';
import 'takeout_data.dart';

/// Why items missing from the newest takeout weren't marked deleted.
enum DeletionCheckSkipReason {
  /// Some of the takeout's numbered CSV files are missing, e.g. a zip part
  /// wasn't picked, so missing items may just be in a file that wasn't read.
  incompleteFiles,

  /// Some rows couldn't be read, so missing items may be in those rows.
  unparsedRows,

  /// The saved data is the newest source, but it came from a takeout that
  /// may have been incomplete, or from before completeness was tracked.
  savedDataUnverified,
}

/// Author channels of two takeouts that don't belong to the same account.
class ChannelMismatch {
  final Set<String> expectedChannelIds;
  final Set<String> foundChannelIds;

  const ChannelMismatch({
    required this.expectedChannelIds,
    required this.foundChannelIds,
  });
}

/// The result of reading picked takeout zips, ready to be confirmed and saved.
class TakeoutImportPlan {
  /// The author channel of the imported takeouts, whose folder the data is
  /// saved in.
  final String accountId;

  final TakeoutData mergedData;

  /// The takeout's channels once imported, main first.
  final List<TakeoutChannel> channels;

  /// [mergedData] encoded for [TakeoutRepository.saveCsvs].
  final Map<String, Uint8List> csvFiles;

  /// IDs no longer on YouTube, including ones already marked deleted.
  final Set<String> goneCommentIds;
  final Set<String> goneLiveChatIds;

  /// How many of the gone IDs weren't already marked deleted.
  final int newlyDeletedCommentCount;
  final int newlyDeletedLiveChatCount;

  /// Items that weren't in the saved data.
  final int newCommentCount;
  final int newLiveChatCount;

  final DeletionCheckSkipReason? commentCheckSkipped;
  final DeletionCheckSkipReason? liveChatCheckSkipped;

  /// Set when replacing saved data with a takeout from another channel.
  final ChannelMismatch? differentAccount;

  /// The takeout selected when this was worked out. Committing is refused
  /// if another one is selected by then, since this was worked out against
  /// it.
  final String? baseTakeoutId;

  const TakeoutImportPlan({
    required this.accountId,
    required this.mergedData,
    this.channels = const [],
    required this.csvFiles,
    required this.goneCommentIds,
    required this.goneLiveChatIds,
    required this.newlyDeletedCommentCount,
    required this.newlyDeletedLiveChatCount,
    required this.newCommentCount,
    required this.newLiveChatCount,
    this.commentCheckSkipped,
    this.liveChatCheckSkipped,
    this.differentAccount,
    this.baseTakeoutId,
  });
}

/// A problem with the picked zips that stops the import before anything is
/// saved.
class TakeoutImportException implements Exception {
  final String message;

  const TakeoutImportException(this.message);

  @override
  String toString() => message;
}

/// The picked takeout belongs to a different YouTube account.
class TakeoutAccountMismatchException extends TakeoutImportException {
  final Set<String> expectedChannelIds;
  final Set<String> foundChannelIds;

  /// Titles of those channels, where the takeouts give them.
  final Map<String, String> titlesById;

  const TakeoutAccountMismatchException(
    super.message, {
    required this.expectedChannelIds,
    required this.foundChannelIds,
    this.titlesById = const {},
  });
}
