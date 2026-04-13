// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'quota_state.dart';

class QuotaStateMapper extends ClassMapperBase<QuotaState> {
  QuotaStateMapper._();

  static QuotaStateMapper? _instance;
  static QuotaStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QuotaStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'QuotaState';

  static int _$unitsUsed(QuotaState v) => v.unitsUsed;
  static const Field<QuotaState, int> _f$unitsUsed = Field(
    'unitsUsed',
    _$unitsUsed,
  );
  static DateTime _$periodStart(QuotaState v) => v.periodStart;
  static const Field<QuotaState, DateTime> _f$periodStart = Field(
    'periodStart',
    _$periodStart,
  );
  static int _$dailyLimit(QuotaState v) => v.dailyLimit;
  static const Field<QuotaState, int> _f$dailyLimit = Field(
    'dailyLimit',
    _$dailyLimit,
    opt: true,
    def: 10000,
  );

  @override
  final MappableFields<QuotaState> fields = const {
    #unitsUsed: _f$unitsUsed,
    #periodStart: _f$periodStart,
    #dailyLimit: _f$dailyLimit,
  };

  static QuotaState _instantiate(DecodingData data) {
    return QuotaState(
      unitsUsed: data.dec(_f$unitsUsed),
      periodStart: data.dec(_f$periodStart),
      dailyLimit: data.dec(_f$dailyLimit),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static QuotaState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<QuotaState>(map);
  }

  static QuotaState fromJson(String json) {
    return ensureInitialized().decodeJson<QuotaState>(json);
  }
}

mixin QuotaStateMappable {
  String toJson() {
    return QuotaStateMapper.ensureInitialized().encodeJson<QuotaState>(
      this as QuotaState,
    );
  }

  Map<String, dynamic> toMap() {
    return QuotaStateMapper.ensureInitialized().encodeMap<QuotaState>(
      this as QuotaState,
    );
  }

  QuotaStateCopyWith<QuotaState, QuotaState, QuotaState> get copyWith =>
      _QuotaStateCopyWithImpl<QuotaState, QuotaState>(
        this as QuotaState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return QuotaStateMapper.ensureInitialized().stringifyValue(
      this as QuotaState,
    );
  }

  @override
  bool operator ==(Object other) {
    return QuotaStateMapper.ensureInitialized().equalsValue(
      this as QuotaState,
      other,
    );
  }

  @override
  int get hashCode {
    return QuotaStateMapper.ensureInitialized().hashValue(this as QuotaState);
  }
}

extension QuotaStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, QuotaState, $Out> {
  QuotaStateCopyWith<$R, QuotaState, $Out> get $asQuotaState =>
      $base.as((v, t, t2) => _QuotaStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class QuotaStateCopyWith<$R, $In extends QuotaState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? unitsUsed, DateTime? periodStart, int? dailyLimit});
  QuotaStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _QuotaStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, QuotaState, $Out>
    implements QuotaStateCopyWith<$R, QuotaState, $Out> {
  _QuotaStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<QuotaState> $mapper =
      QuotaStateMapper.ensureInitialized();
  @override
  $R call({int? unitsUsed, DateTime? periodStart, int? dailyLimit}) => $apply(
    FieldCopyWithData({
      if (unitsUsed != null) #unitsUsed: unitsUsed,
      if (periodStart != null) #periodStart: periodStart,
      if (dailyLimit != null) #dailyLimit: dailyLimit,
    }),
  );
  @override
  QuotaState $make(CopyWithData data) => QuotaState(
    unitsUsed: data.get(#unitsUsed, or: $value.unitsUsed),
    periodStart: data.get(#periodStart, or: $value.periodStart),
    dailyLimit: data.get(#dailyLimit, or: $value.dailyLimit),
  );

  @override
  QuotaStateCopyWith<$R2, QuotaState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _QuotaStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

