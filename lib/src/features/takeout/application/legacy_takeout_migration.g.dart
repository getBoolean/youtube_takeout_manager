// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_takeout_migration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Moves the CSVs saved before takeouts were kept per account into the
/// folder of the channel that wrote most of them, and selects it, once at
/// start-up while no takeout is selected. Throws a
/// [LegacyTakeoutMigrationException], keeping them, when no channel wrote
/// them, rather than showing data tied to no channel.
// Its failure is deterministic, and retrying would parse that data again.

@ProviderFor(legacyTakeoutMigration)
final legacyTakeoutMigrationProvider = LegacyTakeoutMigrationProvider._();

/// Moves the CSVs saved before takeouts were kept per account into the
/// folder of the channel that wrote most of them, and selects it, once at
/// start-up while no takeout is selected. Throws a
/// [LegacyTakeoutMigrationException], keeping them, when no channel wrote
/// them, rather than showing data tied to no channel.
// Its failure is deterministic, and retrying would parse that data again.

final class LegacyTakeoutMigrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Moves the CSVs saved before takeouts were kept per account into the
  /// folder of the channel that wrote most of them, and selects it, once at
  /// start-up while no takeout is selected. Throws a
  /// [LegacyTakeoutMigrationException], keeping them, when no channel wrote
  /// them, rather than showing data tied to no channel.
  // Its failure is deterministic, and retrying would parse that data again.
  LegacyTakeoutMigrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'legacyTakeoutMigrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$legacyTakeoutMigrationHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return legacyTakeoutMigration(ref);
  }
}

String _$legacyTakeoutMigrationHash() =>
    r'cb1283b5148e7b10a1f861d08abaec61dd9c7328';
