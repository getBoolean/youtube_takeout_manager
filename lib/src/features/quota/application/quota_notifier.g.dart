// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quota_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuotaNotifier)
final quotaProvider = QuotaNotifierProvider._();

final class QuotaNotifierProvider
    extends $AsyncNotifierProvider<QuotaNotifier, QuotaState> {
  QuotaNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quotaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quotaNotifierHash();

  @$internal
  @override
  QuotaNotifier create() => QuotaNotifier();
}

String _$quotaNotifierHash() => r'4471d4fae8335a15ae92548e616234eac6cbe34f';

abstract class _$QuotaNotifier extends $AsyncNotifier<QuotaState> {
  FutureOr<QuotaState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<QuotaState>, QuotaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<QuotaState>, QuotaState>,
              AsyncValue<QuotaState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
