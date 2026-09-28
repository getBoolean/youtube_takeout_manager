import 'package:youtube_takeout_manager/src/features/history/domain/history_merge.dart';
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

/// The result of reading picked takeout zips, ready to be confirmed and saved.
class TakeoutImportPlan {
  /// The author channel of the imported takeouts, whose folder the data is
  /// saved in.
  final String accountId;

  final TakeoutData mergedData;

  /// The takeout's channels once imported, main first.
  final List<TakeoutChannel> channels;

  /// IDs no longer on YouTube, including ones already marked deleted.
  final Set<String> goneCommentIds;
  final Set<String> goneLiveChatIds;

  /// The gone IDs that weren't already marked deleted.
  final Set<String> newlyDeletedCommentIds;
  final Set<String> newlyDeletedLiveChatIds;

  /// IDs of items that weren't in the saved data.
  final Set<String> newCommentIds;
  final Set<String> newLiveChatIds;

  int get newlyDeletedCommentCount => newlyDeletedCommentIds.length;
  int get newlyDeletedLiveChatCount => newlyDeletedLiveChatIds.length;
  int get newCommentCount => newCommentIds.length;
  int get newLiveChatCount => newLiveChatIds.length;

  /// The videos the new items are on.
  Set<String> get newItemVideoIds => {
    for (final c in mergedData.comments)
      if (newCommentIds.contains(c.commentId)) ?c.videoId,
    for (final l in mergedData.liveChats)
      if (newLiveChatIds.contains(l.liveChatId)) ?l.videoId,
  };

  final DeletionCheckSkipReason? commentCheckSkipped;
  final DeletionCheckSkipReason? liveChatCheckSkipped;

  /// What it does to the account's watch and search history.
  final HistoryImport history;

  /// Nothing in the picked takeouts named a channel of their account (they
  /// held only subscriptions or history, say), so they go into [accountId],
  /// the takeout shown. The review names it, and is never skipped.
  final bool accountAssumed;

  /// The takeout selected when this was worked out. Committing is refused
  /// if another one is selected by then, since this was worked out against
  /// it.
  final String? baseTakeoutId;

  const TakeoutImportPlan({
    required this.accountId,
    required this.mergedData,
    this.channels = const [],
    required this.goneCommentIds,
    required this.goneLiveChatIds,
    required this.newlyDeletedCommentIds,
    required this.newlyDeletedLiveChatIds,
    required this.newCommentIds,
    required this.newLiveChatIds,
    this.commentCheckSkipped,
    this.liveChatCheckSkipped,
    this.history = HistoryImport.none,
    this.accountAssumed = false,
    this.baseTakeoutId,
  });

  /// Whether there's something to look over before it's saved even as a
  /// first import: items found deleted, a deletion check skipped, or rows
  /// or history that couldn't be read, or takeouts that only the takeout
  /// shown says whose they are.
  bool get needsReview =>
      newlyDeletedCommentCount > 0 ||
      newlyDeletedLiveChatCount > 0 ||
      commentCheckSkipped != null ||
      liveChatCheckSkipped != null ||
      mergedData.skippedCommentRows > 0 ||
      mergedData.skippedLiveChatRows > 0 ||
      history.needsReview ||
      accountAssumed;
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
