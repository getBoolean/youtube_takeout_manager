import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/takeout_parser.dart';
import '../data/takeout_repository.dart';
import '../domain/channel_id.dart';
import '../domain/takeout_data.dart';
import 'takeout_selection_notifier.dart';

part 'legacy_takeout_migration.g.dart';

/// Takeout data saved before takeouts were kept per account couldn't be
/// matched to a channel, so it was left where it is.
class LegacyTakeoutMigrationException implements Exception {
  final String message;

  const LegacyTakeoutMigrationException(this.message);

  @override
  String toString() => message;
}

/// Moves the CSVs saved before takeouts were kept per account into the
/// folder of the channel that wrote most of them, and selects it, once at
/// start-up while no takeout is selected. The channel list shows it moving,
/// or why it couldn't, while nothing is selected. Throws a
/// [LegacyTakeoutMigrationException], keeping them, when no channel wrote
/// them, rather than showing data tied to no channel.
// Its failure is deterministic, and retrying would parse that data again.
@Riverpod(keepAlive: true, retry: _noRetry)
Future<void> legacyTakeoutMigration(Ref ref) async {
  final takeouts = ref.read(takeoutRepositoryProvider);
  if (await ref.read(takeoutSelectionProvider.future) != null) return;
  final legacyCsvs = await takeouts.loadLegacyCsvs();
  if (legacyCsvs == null) return;

  final data = await compute(parseCsvFiles, legacyCsvs);
  // A takeout imported meanwhile stays selected; the data waits, as it does
  // whenever one is.
  if (await ref.read(takeoutSelectionProvider.future) != null) return;
  final accountId = data.mostCommonAuthor;
  if (accountId == null || !isChannelId(accountId)) {
    throw LegacyTakeoutMigrationException(
      "Your saved data couldn't be matched to a YouTube channel "
      '(${accountId ?? 'no channel ID'}). Import your takeout again.',
    );
  }
  await takeouts.saveCsvs(accountId, legacyCsvs);
  if (ref.read(takeoutSelectionProvider).value == null) {
    await ref.read(takeoutSelectionProvider.notifier).select(accountId);
  }
  await takeouts.clearLegacyCsvs();
}

Duration? _noRetry(int retryCount, Object error) => null;
